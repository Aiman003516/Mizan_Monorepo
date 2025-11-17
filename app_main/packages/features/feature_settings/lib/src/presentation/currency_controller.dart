import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

// This provider is fine, but it duplicates one in core_data.
// We will use the one from core_data. This file is now redundant
// but we will refactor it to export the one from core_data for consistency.

// This file is now just an export.
export 'package:core_data/src/app_state_providers.dart' show defaultCurrencyProvider;