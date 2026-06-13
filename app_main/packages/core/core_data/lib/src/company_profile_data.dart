import 'package:core_data/src/preferences_repository.dart';

/// A simple data class to hold the company profile fields.
class CompanyProfileData {
  final String companyName;
  final String userName;
  final String companyAddress;
  final String taxID;
  final String? imagePath;

  CompanyProfileData({
    required this.companyName,
    required this.userName,
    required this.companyAddress,
    required this.taxID,
    this.imagePath,
  });

  /// Factory constructor to load data from the repository
  factory CompanyProfileData.fromRepository(PreferencesRepository repo) {
    return CompanyProfileData(
      companyName: repo.getCompanyName(),
      userName: repo.getUserName(),
      companyAddress: repo.getCompanyAddress(),
      taxID: repo.getTaxID(),
      imagePath: repo.getImagePath(),
    );
  }

  /// Creates a copy of the object with new values.
  CompanyProfileData copyWith({
    String? companyName,
    String? userName,
    String? companyAddress,
    String? taxID,
    String? imagePath,
  }) {
    return CompanyProfileData(
      companyName: companyName ?? this.companyName,
      userName: userName ?? this.userName,
      companyAddress: companyAddress ?? this.companyAddress,
      taxID: taxID ?? this.taxID,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
