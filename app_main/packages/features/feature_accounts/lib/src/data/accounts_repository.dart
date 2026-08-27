/// Compatibility export for account screens.
///
/// Account persistence and query behavior belongs to core_data so other
/// bounded contexts do not depend on feature_accounts. The account UI remains
/// owned by feature_accounts.
export 'package:core_data/core_data.dart'
    show AccountsRepository, accountsRepositoryProvider;
