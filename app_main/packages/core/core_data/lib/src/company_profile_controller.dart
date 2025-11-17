import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/src/preferences_repository.dart';
import 'package:core_data/src/company_profile_data.dart';

// 1. The StateNotifierProvider
final companyProfileProvider =
StateNotifierProvider<CompanyProfileController, CompanyProfileData>((ref) {
  final repo = ref.watch(preferencesRepositoryProvider);
  return CompanyProfileController(repo);
});

// 2. The Controller
class CompanyProfileController extends StateNotifier<CompanyProfileData> {
  CompanyProfileController(this._repo)
      : super(CompanyProfileData.fromRepository(_repo));

  final PreferencesRepository _repo;

  // Save the data
  Future<void> saveProfile({
    required String companyName,
    required String userName,
    required String companyAddress,
    required String taxID,
  }) async {
    // Save to repository
    await _repo.setCompanyName(companyName);
    await _repo.setUserName(userName);
    await _repo.setCompanyAddress(companyAddress);
    await _repo.setTaxID(taxID);

    // Update the state
    state = state.copyWith(
      companyName: companyName,
      userName: userName,
      companyAddress: companyAddress,
      taxID: taxID,
    );
  }
}