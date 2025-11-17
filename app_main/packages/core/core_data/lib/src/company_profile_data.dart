import 'package:core_data/src/preferences_repository.dart';

/// A simple data class to hold the company profile fields.
class CompanyProfileData {
  final String companyName;
  final String userName;
  final String companyAddress;
  final String taxID;

  CompanyProfileData({
    required this.companyName,
    required this.userName,
    required this.companyAddress,
    required this.taxID,
  });

  /// Factory constructor to load data from the repository
  factory CompanyProfileData.fromRepository(PreferencesRepository repo) {
    return CompanyProfileData(
      companyName: repo.getCompanyName(),
      userName: repo.getUserName(),
      companyAddress: repo.getCompanyAddress(),
      taxID: repo.getTaxID(),
    );
  }

  /// Creates a copy of the object with new values.
  CompanyProfileData copyWith({
    String? companyName,
    String? userName,
    String? companyAddress,
    String? taxID,
  }) {
    return CompanyProfileData(
      companyName: companyName ?? this.companyName,
      userName: userName ?? this.userName,
      companyAddress: companyAddress ?? this.companyAddress,
      taxID: taxID ?? this.taxID,
    );
  }
}