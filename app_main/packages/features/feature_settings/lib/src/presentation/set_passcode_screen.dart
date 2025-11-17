import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart';

class SetPasscodeScreen extends ConsumerStatefulWidget {
  const SetPasscodeScreen({super.key});

  @override
  ConsumerState<SetPasscodeScreen> createState() => _SetPasscodeScreenState();
}

class _SetPasscodeScreenState extends ConsumerState<SetPasscodeScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _savePasscode() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final messenger = ScaffoldMessenger.of(context);

    try {
      final pin = _pinController.text;
      final repo = ref.read(preferencesRepositoryProvider);

      await repo.setPasscode(pin);
      await repo.setPasscodeEnabled(true);

      messenger.showSnackBar(SnackBar(
        content: Text(l10n.passcodeSetSuccess),
        backgroundColor: Colors.green,
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      messenger.showSnackBar(SnackBar(
        content: Text('${l10n.failedToSavePasscode} $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.setPasscode),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.setPasscodeHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: l10n.newPin,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.pin),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterPin;
                  }
                  if (value.length != 4) return l10n.pinMustBe4Digits;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPinController,
                decoration: InputDecoration(
                  labelText: l10n.confirmPin,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.pin),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                validator: (value) {
                  if (value != _pinController.text) return l10n.pinsDoNotMatch;
                  return null;
                },
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ))
                    : const Icon(Icons.save),
                label: Text(l10n.savePasscode),
                onPressed: _isLoading ? null : _savePasscode,
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