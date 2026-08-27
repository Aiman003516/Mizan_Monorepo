#include <jni.h>
#include <unistd.h>

#include <algorithm>
#include <mutex>
#include <string>
#include <vector>

#include <llama.h>

namespace {

constexpr char kLogTag[] = "MizanLocalAi";
constexpr int32_t kMaxPromptChars = 7000;
constexpr int32_t kMaxInputTokens = 1536;
constexpr int32_t kMaxGeneratedTokens = 384;

// Constrain the output to the versioned Mizan proposal shape. Dart remains the
// authoritative semantic validator for fields, entities, routes, and actions.
constexpr char kProposalGrammar[] = R"GBNF(
root ::= "{" ws "\"schema_version\"" ws ":" ws "\"mizan.local-ai.proposal/v1\"" ws "," ws "\"intent\"" ws ":" ws intent ws "," ws "\"action_type\"" ws ":" ws action-type ws "," ws "\"fields\"" ws ":" ws object ws "," ws "\"entities\"" ws ":" ws array ws "," ws "\"missing_fields\"" ws ":" ws string-array ws "," ws "\"confidence\"" ws ":" ws number ws "," ws "\"requires_confirmation\"" ws ":" ws boolean ws "," ws "\"locale\"" ws ":" ws locale ws "," ws "\"source\"" ws ":" ws "\"local\"" ws "," ws "\"route\"" ws ":" ws route-value ws "}"
intent ::= "\"explain\"" | "\"navigate\"" | "\"propose_mutation\"" | "\"request_missing_information\"" | "\"unsupported\""
action-type ::= "\"none\"" | "\"navigate\"" | "\"open_screen\"" | "\"search_entity\"" | "\"customer_update\"" | "\"vendor_update\"" | "\"invoice_update\"" | "\"bill_update\"" | "\"balance_adjustment\"" | "\"journal_entry_post\"" | "\"customer_archive\"" | "\"vendor_archive\"" | "\"invoice_void\"" | "\"bill_void\""
locale ::= "\"ar\"" | "\"en\""
route-value ::= string | "null"
string-array ::= "[" ws (string (ws "," ws string)*)? ws "]"
object ::= "{" ws (string ws ":" ws value (ws "," ws string ws ":" ws value)*)? ws "}"
array ::= "[" ws (value (ws "," ws value)*)? ws "]"
value ::= object | array | string | number | boolean | "null"
string ::= "\"" char* "\"" ws
char ::= [^"\\\x7F\x00-\x1F] | [\\] escape
escape ::= ["\\/bfnrt] | "u" [0-9a-fA-F]{4}
number ::= "-"? ("0" | [1-9] [0-9]*) ("." [0-9]+)? ([eE] [-+]? [0-9]+)? ws
boolean ::= "true" | "false"
ws ::= [ \t\n\r]*
)GBNF";

class LocalAiRuntime {
 public:
  static LocalAiRuntime& Instance() {
    static LocalAiRuntime instance;
    return instance;
  }

  bool LoadModel(const std::string& path) {
    std::lock_guard<std::mutex> lock(mutex_);
    UnloadModelInternal();
    if (path.empty()) {
      return false;
    }

    llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = 0;
    model_params.check_tensors = false;
    model_ = llama_model_load_from_file(path.c_str(), model_params);
    if (model_ == nullptr) {
      return false;
    }

    llama_context_params context_params = llama_context_default_params();
    context_params.n_ctx = 2048;
    const long cores = sysconf(_SC_NPROCESSORS_ONLN);
    const long threads = cores > 1 ? cores - 1 : 1;
    context_params.n_threads = static_cast<int32_t>(std::max(1L, threads));
    context_params.n_threads_batch = context_params.n_threads;

    context_ = llama_init_from_model(model_, context_params);
    if (context_ == nullptr) {
      UnloadModelInternal();
      return false;
    }
    return true;
  }

  std::string Infer(const std::string& text, const std::string& locale) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (model_ == nullptr || context_ == nullptr || text.empty()) {
      return {};
    }

    llama_memory_clear(llama_get_memory(context_), true);
    const llama_vocab* vocab = llama_model_get_vocab(model_);
    const std::string prompt =
        "<|im_start|>system\n"
        "You are the private Mizan accounting assistant. Do not use thinking mode. "
        "Return only one valid JSON object using this exact schema: "
        "{\"schema_version\":\"mizan.local-ai.proposal/v1\","
        "\"intent\":\"explain|navigate|propose_mutation|request_missing_information|unsupported\","
        "\"action_type\":\"none|navigate|open_screen|search_entity|customer_update|"
        "vendor_update|invoice_update|bill_update|balance_adjustment|journal_entry_post|"
        "customer_archive|vendor_archive|invoice_void|bill_void\","
        "\"fields\":{},\"entities\":[],\"missing_fields\":[],"
        "\"confidence\":0.0,\"requires_confirmation\":false,"
        "\"locale\":\"ar or en\",\"source\":\"local\",\"route\":null}. "
        "Use explain for capability or workflow questions, navigate for a page request, "
        "request_missing_information when required details are absent, and propose_mutation "
        "only for a reviewable draft. Allowed routes include customers, vendors, crmPipeline, "
        "crm360, procurement, pos, reportsHub, manageAccounts, manageProducts, "
        "manageCategories, orderHistory, settings, reportProfitAndLoss, reportBalanceSheet, "
        "and reportTrialBalance. Never execute an action. Never invent record IDs. Locale: " +
        locale +
        ". User request: /no_think " + text + "<|im_end|>\n"
        "<|im_start|>assistant\n";

    if (prompt.size() > kMaxPromptChars) {
      return {};
    }

    std::vector<llama_token> tokens(prompt.size() + 1);
    const int32_t token_count = llama_tokenize(
        vocab, prompt.c_str(), static_cast<int32_t>(prompt.size()), tokens.data(),
        static_cast<int32_t>(tokens.size()), true, true);
    if (token_count < 0 || token_count > kMaxInputTokens) {
      return {};
    }
    tokens.resize(static_cast<size_t>(token_count));

    llama_batch batch = llama_batch_init(token_count, 0, 1);
    for (int32_t i = 0; i < token_count; ++i) {
      batch.token[i] = tokens[static_cast<size_t>(i)];
      batch.pos[i] = i;
      batch.n_seq_id[i] = 1;
      batch.seq_id[i][0] = 0;
      batch.logits[i] = i == token_count - 1;
    }
    batch.n_tokens = token_count;

    if (llama_decode(context_, batch) != 0) {
      llama_batch_free(batch);
      return {};
    }
    llama_batch_free(batch);

    llama_sampler_chain_params sampler_params =
        llama_sampler_chain_default_params();
    llama_sampler* sampler = llama_sampler_chain_init(sampler_params);
    if (sampler == nullptr) {
      return {};
    }
    llama_sampler_chain_add(sampler, llama_sampler_init_greedy());

    std::string output;
    int32_t position = token_count;
    while (position < token_count + kMaxGeneratedTokens) {
      llama_token token = llama_sampler_sample(sampler, context_, -1);
      if (llama_vocab_is_eog(vocab, token)) {
        break;
      }

      char piece[256];
      const int32_t piece_length =
          llama_token_to_piece(vocab, token, piece, sizeof(piece), 0, false);
      if (piece_length > 0) {
        output.append(piece, piece_length);
      }

      // llama_batch_get_one intentionally leaves position/sequence arrays null;
      // llama.cpp tracks the single-sequence position automatically.
      llama_batch next_batch = llama_batch_get_one(&token, 1);
      if (llama_decode(context_, next_batch) != 0) {
        output.clear();
        break;
      }
      ++position;
    }

    llama_sampler_free(sampler);
    const size_t first_brace = output.find('{');
    const size_t last_brace = output.rfind('}');
    if (first_brace != 0 || last_brace != output.size() - 1 ||
        last_brace <= first_brace) {
      return {};
    }
    return output;
  }

  void UnloadModel() {
    std::lock_guard<std::mutex> lock(mutex_);
    UnloadModelInternal();
  }

 private:
  LocalAiRuntime() { llama_backend_init(); }

  ~LocalAiRuntime() {
    UnloadModelInternal();
    llama_backend_free();
  }

  void UnloadModelInternal() {
    if (context_ != nullptr) {
      llama_free(context_);
      context_ = nullptr;
    }
    if (model_ != nullptr) {
      llama_model_free(model_);
      model_ = nullptr;
    }
  }

  std::mutex mutex_;
  llama_model* model_ = nullptr;
  llama_context* context_ = nullptr;
};

std::string ToString(JNIEnv* env, jstring value) {
  if (value == nullptr) {
    return {};
  }
  const char* chars = env->GetStringUTFChars(value, nullptr);
  if (chars == nullptr) {
    return {};
  }
  std::string result(chars);
  env->ReleaseStringUTFChars(value, chars);
  return result;
}

}  // namespace

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_mizan_LocalAiNative_loadModel(JNIEnv* env, jclass,
                                                jstring path) {
  return LocalAiRuntime::Instance().LoadModel(ToString(env, path)) ? JNI_TRUE
                                                                    : JNI_FALSE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_mizan_LocalAiNative_infer(JNIEnv* env, jclass, jstring text,
                                            jstring locale) {
  const std::string output = LocalAiRuntime::Instance().Infer(
      ToString(env, text), ToString(env, locale));
  if (output.empty()) {
    return nullptr;
  }
  return env->NewStringUTF(output.c_str());
}

extern "C" JNIEXPORT void JNICALL
Java_com_example_mizan_LocalAiNative_unloadModel(JNIEnv*, jclass) {
  LocalAiRuntime::Instance().UnloadModel();
}
