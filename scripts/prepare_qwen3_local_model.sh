#!/usr/bin/env bash
set -euo pipefail

MODEL_URL="https://huggingface.co/bartowski/Qwen_Qwen3-0.6B-GGUF/resolve/60b85c0e3d8fe0f6474f406922a26d12aca4550d/Qwen_Qwen3-0.6B-Q4_K_M.gguf"
MODEL_NAME="Qwen_Qwen3-0.6B-Q4_K_M.gguf"
EXPECTED_SHA256="9acfc1e001311f34b4252001b626f2e466d592a42065f66571bff3790d4e1b14"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="${REPO_ROOT}/.local_ai_model_cache"
ASSET_DIR="${REPO_ROOT}/app_main/apps/assets/local_ai"
MODEL_PATH="${CACHE_DIR}/${MODEL_NAME}"

mkdir -p "${CACHE_DIR}" "${ASSET_DIR}"
if [[ ! -f "${MODEL_PATH}" ]]; then
  echo "Downloading ${MODEL_NAME} from the pinned revision..."
  curl --fail --location --retry 3 --retry-delay 5 --continue-at - \
    --output "${MODEL_PATH}.partial" "${MODEL_URL}"
  mv "${MODEL_PATH}.partial" "${MODEL_PATH}"
fi

actual_sha256="$(sha256sum "${MODEL_PATH}" | awk '{print $1}')"
if [[ "${actual_sha256}" != "${EXPECTED_SHA256}" ]]; then
  echo "Checksum verification failed for ${MODEL_NAME}" >&2
  echo "Expected: ${EXPECTED_SHA256}" >&2
  echo "Actual:   ${actual_sha256}" >&2
  exit 1
fi

install -m 0644 "${MODEL_PATH}" "${ASSET_DIR}/${MODEL_NAME}"
printf '%s\n' "Verified ${MODEL_NAME}" "SHA-256: ${actual_sha256}" "Copied to: ${ASSET_DIR}/${MODEL_NAME}"
