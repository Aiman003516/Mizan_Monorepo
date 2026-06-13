import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:share_plus/share_plus.dart'; // Ensure you added this to pubspec

class InviteStaffScreen extends ConsumerStatefulWidget {
  const InviteStaffScreen({super.key});

  @override
  ConsumerState<InviteStaffScreen> createState() => _InviteStaffScreenState();
}

class _InviteStaffScreenState extends ConsumerState<InviteStaffScreen> {
  AppRole? _selectedRole;
  String? _generatedCode;
  bool _isLoading = false;

  Future<void> _generateCode() async {
    if (_selectedRole == null) return;

    setState(() => _isLoading = true);
    try {
      final code = await ref.read(staffRepositoryProvider).createInvite(_selectedRole!.id);
      setState(() {
        _generatedCode = code;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _shareInvite() {
    if (_generatedCode == null) return;
    final text = "Join my business on Mizan!\n\n"
        "1. Download the App\n"
        "2. Sign In\n"
        "3. Select 'Join Business' and enter code: $_generatedCode\n\n"
        "(Valid for 24 hours)";
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Invite Staff")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "1. Select a Role",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            rolesAsync.when(
              data: (roles) {
                // Filter out Admin/Owner roles usually, but for now show all except Owner if you want
                final assignableRoles = roles.where((r) => r.id != 'owner').toList();
                
                return DropdownButtonFormField<AppRole>(
                  initialValue: _selectedRole,
                  hint: const Text("Choose Role (e.g. Cashier)"),
                  items: assignableRoles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() {
                    _selectedRole = val;
                    _generatedCode = null; // Reset code if role changes
                  }),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text("Error loading roles: $err"),
            ),
            const SizedBox(height: 32),
            
            if (_generatedCode == null)
              ElevatedButton(
                onPressed: (_selectedRole == null || _isLoading) ? null : _generateCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: context.appColors.onPrimary,
                ),
                child: _isLoading 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.appColors.onPrimary)) 
                    : const Text("Generate Invite Code"),
              ),

            if (_generatedCode != null) ...[
              const Divider(height: 40),
              const Text(
                "2. Share Code",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.appColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appColors.primary),
                ),
                child: Column(
                  children: [
                    Text(
                      _generatedCode!,
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 4,
                        color: context.appColors.onSurface
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("Valid for 24 hours", style: TextStyle(color: context.appColors.subtleText)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _shareInvite,
                icon: const Icon(Icons.share),
                label: const Text("Share via WhatsApp / Telegram"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: context.appColors.success,
                  foregroundColor: context.appColors.onPrimary,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}