import 'package:firebase_core/firebase_core.dart';
import 'env_config.dart';
import 'firebase_options_dev.dart' as dev_options;
import 'firebase_options_prod.dart' as prod_options;

/// The Logic Switch: Decides which Firebase Keys to use
/// based on the --dart-define=APP_ENV variable.
class MizanFirebaseConfig {
  static FirebaseOptions get currentPlatform {
    if (EnvConfig.appEnv == 'prod') {
      // THE REAL BANK VAULT
      return prod_options.DefaultFirebaseOptions.currentPlatform;
    } else {
      // THE SANDBOX (Default)
      return dev_options.DefaultFirebaseOptions.currentPlatform;
    }
  }
}