cmake_minimum_required(VERSION 3.22.1)
project(mizan_local_ai LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# The source is prepared once by scripts/prepare_llama_cpp_windows.ps1. The
# archive is platform-neutral and can be compiled by the Android NDK for the
# selected ABI without a build-time GitHub clone.
set(MIZAN_LLAMA_CPP_REVISION "47c786924ad1ab7e91da2cdc72fcdb563780c2bd")
set(MIZAN_LLAMA_CPP_SOURCE_DIR
  "${CMAKE_CURRENT_LIST_DIR}/../../../../../../../.local_llama_cpp_cache/llama.cpp-${MIZAN_LLAMA_CPP_REVISION}"
  CACHE PATH "Prepared local llama.cpp source directory")
if(NOT EXISTS "${MIZAN_LLAMA_CPP_SOURCE_DIR}/CMakeLists.txt")
  message(FATAL_ERROR
    "Mizan requires the prepared llama.cpp source at '${MIZAN_LLAMA_CPP_SOURCE_DIR}'. "
    "Run scripts\\prepare_llama_cpp_windows.ps1 from the repository root, then retry the Android build.")
endif()

set(LLAMA_STANDALONE OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_COMMON OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_APP OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_MTMD OFF CACHE BOOL "" FORCE)
set(LLAMA_OPENSSL OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_CPU_REPACK OFF CACHE BOOL "" FORCE)
set(GGML_LLAMAFILE OFF CACHE BOOL "" FORCE)
add_subdirectory("${MIZAN_LLAMA_CPP_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/mizan-llama-cpp" EXCLUDE_FROM_ALL)

add_library(mizan_local_ai SHARED local_ai_android.cpp)
target_include_directories(mizan_local_ai PRIVATE "${MIZAN_LLAMA_CPP_SOURCE_DIR}/include")
target_link_libraries(mizan_local_ai PRIVATE llama log)
