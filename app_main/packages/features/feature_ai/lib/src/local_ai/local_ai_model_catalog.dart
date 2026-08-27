import 'local_ai_native_bridge.dart';

/// Exact model artifact selected for the first on-device Mizan pilot.
///
/// The binary is intentionally not stored in Git. The preparation script
/// downloads the pinned revision and verifies this SHA-256 before copying the
/// artifact into the Android app asset directory.
const qwen3MizanLocalModel = LocalAiModelManifest(
  modelId: 'Qwen/Qwen3-0.6B',
  modelVersion: '0.6B@60b85c0e3d8fe0f6474f406922a26d12aca4550d',
  artifactName: 'Qwen_Qwen3-0.6B-Q4_K_M.gguf',
  sha256: '9acfc1e001311f34b4252001b626f2e466d592a42065f66571bff3790d4e1b14',
  tokenizerVersion: 'qwen3-chat-template-v1',
  supportedLocales: ['ar', 'en'],
  minimumAppVersion: '1.0.0+1',
  task: 'proposal_extraction',
  quantization: 'q4_k_m',
  schemaVersion: 'mizan.local-ai.model/v2',
  runtime: 'llama_cpp',
);
