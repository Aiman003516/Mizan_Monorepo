import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// Local / Shared Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/src/company_profile_controller.dart';
import 'package:shared_ui/shared_ui.dart'; // Ensure shared_ui barrel exports ImagePickerWidget, or use direct path
import 'package:shared_ui/src/widgets/image_picker_widget.dart';
import 'package:shared_services/src/image_picker_service.dart';

class CompanyProfileScreen extends ConsumerStatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  ConsumerState<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends ConsumerState<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxIDController = TextEditingController();

  String? _selectedImagePath;
  bool _isLoading = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(companyProfileProvider);
    _companyNameController.text = profile.companyName;
    _userNameController.text = profile.userName;
    _addressController.text = profile.companyAddress;
    _taxIDController.text = profile.taxID;

    // Attempt to load existing image path if your model supports it
    // Update `.imagePath` to your exact property name if it differs
    _selectedImagePath = profile.imagePath;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _userNameController.dispose();
    _addressController.dispose();
    _taxIDController.dispose();
    super.dispose();
  }

  Future<void> _handlePickImage() async {
    final imageService = ref.read(imagePickerServiceProvider);

    try {
      // Using the service you already built which handles Android/iOS/Windows perfectly
      final pickedPath = await imageService.pickAndCopyImage(
        ImageSource.gallery,
      );

      if (pickedPath != null && mounted) {
        setState(() {
          _selectedImagePath = pickedPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to pick image: $e"),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }

  void _handleRemoveImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      // Update this call to include `imagePath: _selectedImagePath`
      // if your companyProfileProvider supports it.
      await ref
          .read(companyProfileProvider.notifier)
          .saveProfile(
            companyName: _companyNameController.text.trim(),
            userName: _userNameController.text.trim(),
            companyAddress: _addressController.text.trim(),
            taxID: _taxIDController.text.trim(),
            imagePath: _selectedImagePath,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileSavedSuccess),
            backgroundColor: context.appColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToSaveProfile} $e'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.companyProfile),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
            tooltip: l10n.save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Utilizing your existing custom ImagePickerWidget
              ImagePickerWidget(
                imagePath: _selectedImagePath,
                onPickImage: _handlePickImage,
                onRemoveImage: _handleRemoveImage,
              ),
              const SizedBox(height: 32),

              Text(
                l10n.companyProfileReportHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _companyNameController,
                decoration: InputDecoration(
                  labelText: l10n.companyName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterCompanyName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _userNameController,
                decoration: InputDecoration(
                  labelText: l10n.yourName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: l10n.companyAddress,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taxIDController,
                decoration: InputDecoration(
                  labelText: l10n.taxID,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.receipt),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.appColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(l10n.saveProfile),
                onPressed: _isLoading ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
