/// Compatibility export for account list providers.
///
/// Account query providers are owned by core_data so other bounded contexts can
/// consume the public account contract without depending on feature_accounts.
export 'package:core_data/core_data.dart'
    show accountsStreamProvider, allAccountsStreamProvider;
