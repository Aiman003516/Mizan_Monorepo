#include "local_ai_windows.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <llama.h>

#include <windows.h>
#include <bcrypt.h>

#include <algorithm>
#include <array>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <mutex>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#pragma comment(lib, "bcrypt.lib")

namespace {

constexpr char kArtifactName[] = "Qwen_Qwen3-0.6B-Q4_K_M.gguf";
constexpr char kArtifactSha256[] =
    "9acfc1e001311f34b4252001b626f2e466d592a42065f66571bff3790d4e1b14";

flutter::EncodableValue StatusMap(const char* status,
                                  const char* message = nullptr,
                                  const std::string* proposal = nullptr) {
  flutter::EncodableMap map;
  map[flutter::EncodableValue("status")] = flutter::EncodableValue(status);
  if (message != nullptr) {
    map[flutter::EncodableValue("message")] = flutter::EncodableValue(message);
  }
  if (proposal != nullptr) {
    map[flutter::EncodableValue("proposal_json")] =
        flutter::EncodableValue(*proposal);
  }
  return flutter::EncodableValue(map);
}

std::filesystem::path ModelAssetPath() {
  std::vector<char> buffer(MAX_PATH);
  DWORD length = 0;
  do {
    buffer.resize(buffer.size() * 2);
    length = GetModuleFileNameA(nullptr, buffer.data(),
                                static_cast<DWORD>(buffer.size()));
  } while (length == buffer.size());

  if (length == 0) {
    return {};
  }
  std::filesystem::path executable(
      std::string(buffer.data(), static_cast<size_t>(length)));
  return executable.parent_path() / "data" / "flutter_assets" / "assets" /
         "local_ai" / kArtifactName;
}

bool IsPinnedManifest(const std::string& manifest_json) {
  return manifest_json.find("\"schema_version\":\"mizan.local-ai.model/v2\"") !=
             std::string::npos &&
         manifest_json.find("\"runtime\":\"llama_cpp\"") !=
             std::string::npos &&
         manifest_json.find("\"artifact_name\":\"" +
                           std::string(kArtifactName) + "\"") !=
             std::string::npos &&
         manifest_json.find("\"sha256\":\"" +
                           std::string(kArtifactSha256) + "\"") !=
             std::string::npos;
}

bool VerifySha256(const std::filesystem::path& path) {
  BCRYPT_ALG_HANDLE algorithm = nullptr;
  if (BCryptOpenAlgorithmProvider(&algorithm, BCRYPT_SHA256_ALGORITHM, nullptr,
                                  0) != 0) {
    return false;
  }

  DWORD object_length = 0;
  DWORD result_length = 0;
  if (BCryptGetProperty(algorithm, BCRYPT_OBJECT_LENGTH,
                        reinterpret_cast<PUCHAR>(&object_length),
                        sizeof(object_length), &result_length, 0) != 0) {
    BCryptCloseAlgorithmProvider(algorithm, 0);
    return false;
  }

  std::vector<UCHAR> object(object_length);
  BCRYPT_HASH_HANDLE hash = nullptr;
  if (BCryptCreateHash(algorithm, &hash, object.data(), object.size(), nullptr,
                       0, 0) != 0) {
    BCryptCloseAlgorithmProvider(algorithm, 0);
    return false;
  }

  std::ifstream input(path, std::ios::binary);
  std::array<char, 1024 * 1024> buffer{};
  bool ok = input.good();
  while (ok && input.read(buffer.data(), buffer.size())) {
    ok = BCryptHashData(hash, reinterpret_cast<PUCHAR>(buffer.data()),
                        static_cast<ULONG>(input.gcount()), 0) == 0;
  }
  if (ok && input.gcount() > 0) {
    ok = BCryptHashData(hash, reinterpret_cast<PUCHAR>(buffer.data()),
                        static_cast<ULONG>(input.gcount()), 0) == 0;
  }

  std::array<UCHAR, 32> digest{};
  if (ok) {
    ok = BCryptFinishHash(hash, digest.data(), digest.size(), 0) == 0;
  }
  BCryptDestroyHash(hash);
  BCryptCloseAlgorithmProvider(algorithm, 0);
  if (!ok) return false;

  std::ostringstream actual;
  actual << std::hex << std::setfill('0');
  for (const auto byte : digest) {
    actual << std::setw(2) << static_cast<unsigned int>(byte);
  }
  return actual.str() == kArtifactSha256;
}

class LocalAiRuntime {
 public:
  static LocalAiRuntime& GetInstance() {
    static LocalAiRuntime instance;
    return instance;
  }

  bool LoadModel(const std::filesystem::path& path) {
    std::lock_guard<std::mutex> lock(mutex_);
    UnloadModelInternal();

    if (path.empty() || !std::filesystem::is_regular_file(path)) {
      return false;
    }

    llama_model_params mparams = llama_model_default_params();
    mparams.n_gpu_layers = 0;  // Conservative CPU-only Windows path.
    mparams.check_tensors = false; // SHA-256 is verified before loading.

    model_ = llama_model_load_from_file(path.string().c_str(), mparams);
    if (!model_) {
      return false;
    }

    llama_context_params cparams = llama_context_default_params();
    cparams.n_ctx = 2048;
    const auto hardware_threads = std::thread::hardware_concurrency();
    cparams.n_threads = static_cast<int32_t>(
        std::max(1u, hardware_threads > 1 ? hardware_threads - 1 : 1));
    cparams.n_threads_batch = cparams.n_threads;

    ctx_ = llama_init_from_model(model_, cparams);
    if (!ctx_) {
      UnloadModelInternal();
      return false;
    }

    return true;
  }

  std::string Infer(const std::string& text) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!ctx_ || !model_) {
      return {};
    }

    llama_memory_clear(llama_get_memory(ctx_), true);
    const struct llama_vocab* vocab = llama_model_get_vocab(model_);
    const std::string prompt =
        "<|im_start|>system\n"
        "You are the private Mizan accounting assistant. Do not use thinking mode. "
        "Return only one valid "
        "JSON object using this exact schema: {\"schema_version\":"
        "\"mizan.local-ai.proposal/v1\",\"intent\":\"explain|navigate|"
        "propose_mutation|request_missing_information|unsupported\","
        "\"action_type\":\"none|navigate|open_screen|search_entity|"
        "customer_update|vendor_update|invoice_update|bill_update|balance_adjustment|"
        "journal_entry_post|customer_archive|vendor_archive|invoice_void|bill_void\","
        "\"fields\":{},\"entities\":[],\"missing_fields\":[],"
        "\"confidence\":0.0,\"requires_confirmation\":false,"
        "\"locale\":\"en or ar\",\"source\":\"local\"}."
        " Never execute an action. Never invent record IDs. User request: /no_think " +
        text + "<|im_end|>\n<|im_start|>assistant\n";

    if (prompt.length() > 7000) {
      return {};
    }

    std::vector<llama_token> tokens(prompt.length() + 1);
    int32_t n_tokens = llama_tokenize(
        vocab, prompt.c_str(), static_cast<int32_t>(prompt.length()),
        tokens.data(), static_cast<int32_t>(tokens.size()), true, true);
    if (n_tokens < 0 || n_tokens > 1536) {
      return {};
    }
    tokens.resize(static_cast<size_t>(n_tokens));

    llama_batch batch = llama_batch_init(n_tokens, 0, 1);
    for (int32_t i = 0; i < n_tokens; ++i) {
      batch.token[i] = tokens[static_cast<size_t>(i)];
      batch.pos[i] = i;
      batch.n_seq_id[i] = 1;
      batch.seq_id[i][0] = 0;
      batch.logits[i] = i == n_tokens - 1;
    }
    batch.n_tokens = n_tokens;

    if (llama_decode(ctx_, batch) != 0) {
      llama_batch_free(batch);
      return {};
    }
    llama_batch_free(batch);

    struct llama_sampler_chain_params sparams =
        llama_sampler_chain_default_params();
    struct llama_sampler* sampler = llama_sampler_chain_init(sparams);
    if (!sampler) {
      return {};
    }
    llama_sampler_chain_add(sampler, llama_sampler_init_greedy());

    std::string result;
    int32_t position = n_tokens;
    constexpr int32_t kMaxGeneratedTokens = 384;
    while (position < n_tokens + kMaxGeneratedTokens) {
      llama_token token = llama_sampler_sample(sampler, ctx_, -1);
      if (llama_vocab_is_eog(vocab, token)) {
        break;
      }

      char piece[256];
      const int32_t piece_length =
          llama_token_to_piece(vocab, token, piece, sizeof(piece), 0, false);
      if (piece_length > 0) {
        result.append(piece, piece_length);
      }

      // llama_batch_get_one intentionally leaves position/sequence arrays null;
      // llama.cpp tracks the single sequence position automatically.
      llama_batch next_batch = llama_batch_get_one(&token, 1);
      if (llama_decode(ctx_, next_batch) != 0) {
        result.clear();
        break;
      }
      ++position;
    }

    llama_sampler_free(sampler);
    const auto first_brace = result.find('{');
    const auto last_brace = result.rfind('}');
    if (first_brace == std::string::npos || last_brace <= first_brace) {
      return {};
    }
    return result.substr(first_brace, last_brace - first_brace + 1);
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
    if (ctx_) {
      llama_free(ctx_);
      ctx_ = nullptr;
    }
    if (model_) {
      llama_model_free(model_);
      model_ = nullptr;
    }
  }

  std::mutex mutex_;
  struct llama_model* model_ = nullptr;
  struct llama_context* ctx_ = nullptr;
};

}  // namespace

void LocalAiWindowsChannel::Register(flutter::FlutterEngine* engine) {
  auto channel = std::make_unique<
      flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "com.mizan/local_ai",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler([](const auto& call, auto result) {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());

    if (call.method_name() == "load_model") {
      if (!args) {
        result->Error("INVALID_ARGS", "Missing model arguments");
        return;
      }
      const auto manifest_it =
          args->find(flutter::EncodableValue("manifest_json"));
      if (manifest_it == args->end() ||
          !std::holds_alternative<std::string>(manifest_it->second)) {
        result->Error("INVALID_ARGS", "Missing manifest_json");
        return;
      }
      const auto& manifest_json = std::get<std::string>(manifest_it->second);
      if (!IsPinnedManifest(manifest_json)) {
        result->Error("INVALID_MANIFEST", "Model manifest is not the pinned Qwen3 artifact");
        return;
      }

      const auto path = ModelAssetPath();
      if (!VerifySha256(path)) {
        result->Success(StatusMap("unavailable", "Pinned local model checksum verification failed"));
        return;
      }
      if (LocalAiRuntime::GetInstance().LoadModel(path)) {
        result->Success(StatusMap("ready"));
      } else {
        result->Success(StatusMap("unavailable", "Pinned local model asset could not be loaded"));
      }
      return;
    }

    if (call.method_name() == "infer") {
      if (!args) {
        result->Error("INVALID_ARGS", "Missing inference arguments");
        return;
      }
      const auto text_it = args->find(flutter::EncodableValue("text"));
      if (text_it == args->end() ||
          !std::holds_alternative<std::string>(text_it->second)) {
        result->Error("INVALID_ARGS", "Missing or invalid text");
        return;
      }
      const auto proposal =
          LocalAiRuntime::GetInstance().Infer(
              std::get<std::string>(text_it->second));
      if (proposal.empty()) {
        result->Success(StatusMap("failed", "Local llama.cpp inference failed"));
      } else {
        result->Success(StatusMap("ready", nullptr, &proposal));
      }
      return;
    }

    if (call.method_name() == "unload_model") {
      LocalAiRuntime::GetInstance().UnloadModel();
      result->Success();
      return;
    }

    result->NotImplemented();
  });

  // Keep the channel alive for the lifetime of the engine.
  static std::vector<std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>>
      channels;
  channels.push_back(std::move(channel));
}
