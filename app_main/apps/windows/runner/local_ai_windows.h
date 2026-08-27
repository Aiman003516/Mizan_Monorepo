#ifndef RUNNER_LOCAL_AI_WINDOWS_H_
#define RUNNER_LOCAL_AI_WINDOWS_H_

#include <memory>

#include <flutter/flutter_engine.h>

class LocalAiWindowsChannel {
 public:
  static void Register(flutter::FlutterEngine* engine);
};

#endif  // RUNNER_LOCAL_AI_WINDOWS_H_
