import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart';
import 'package:feature_settings/src/presentation/set_passcode_screen.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState
    extends ConsumerState<SecuritySettingsScreen> {
  late bool _isPasscodeEnabled;
  late bool _isBiometricsEnabled;
  bool _isLoading = true;
  bool _canUseBiometrics = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(preferencesRepositoryProvider);
    final auth = LocalAuthentication();

    final isPasscode = repo.isPasscodeEnabled();
    final isBiometrics = repo.isBiometricsEnabled();

    final canCheck = await auth.canCheckBiometrics;
    final hasHardware = await auth.isDeviceSupported();

    if (mounted) {
      setState(() {
        _isPasscodeEnabled = isPasscode;
        _isBiometricsEnabled = isBiometrics;
        _canUseBiometrics = canCheck || hasHardware;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.securityOptions)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final repo = ref.read(preferencesRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.securityOptions),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.requirePasscode),
            subtitle: Text(l10n.toggleSecurity),
            value: _isPasscodeEnabled,
            onChanged: (bool value) async {
              if (value == true) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SetPasscodeScreen(),
                  ),
                );
                _loadSettings();
              } else {
                await repo.clearPasscode();
                await repo.setPasscodeEnabled(false);
                await repo.setBiometricsEnabled(false);
                setState(() {
                  _isPasscodeEnabled = false;
                  _isBiometricsEnabled = false;
                });
                messenger.showSnackBar(SnackBar(
                  content: Text(l10n.passcodeRemoved),
                ));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: Text(l10n.setChangePasscode),
            subtitle:
            _isPasscodeEnabled ? const Text('********') : Text(l10n.notSet),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SetPasscodeScreen(),
              ));
              _loadSettings();
            },
          ),
          if (_canUseBiometrics)
            SwitchListTile(
              title: Text(l10n.useBiometrics),
              subtitle: Text(l10n.useBiometricsHint),
              value: _isBiometricsEnabled,
              onChanged: !_isPasscodeEnabled
                  ? null
                  : (bool value) async {
                await repo.setBiometricsEnabled(value);
                setState(() {
                  _isBiometricsEnabled = value;
                });
              },
            ),
        ],
      ),
    );
  }
}