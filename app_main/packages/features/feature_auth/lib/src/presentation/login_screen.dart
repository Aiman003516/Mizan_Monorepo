// FILE: packages/features/feature_auth/lib/src/presentation/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:core_l10n/app_localizations.dart';
import 'package:feature_auth/src/presentation/auth_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // 🔒 FIX 1: Decoupled Asset Strategy (Phase 2)
    // We strictly use the high-fidelity, full-bleed asset for the UI.
    // This ensures the logo is large and crisp, unrelated to the Android Icon system.
    const String logoAsset = 'assets/images/mizan_full.png';

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated_online) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }

      if (next.status == AuthStatus.unauthenticated &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    final authState = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signIn),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // 🖼️ BRAND LOGO
              // Uses 'mizan_full.png' so it fills the 120 height perfectly.
              Image.asset(
                logoAsset, 
                height: 120,
              ),
              
              const SizedBox(height: 24),
              Text(
                l10n.welcomeToMizan,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.signInToSync,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              const Spacer(),
              
              // 🔒 FIX 2: THE LAYOUT LOCK (Phase 3)
              // We wrap the logic in a SizedBox of height 52.
              // This guarantees the column never shrinks, preventing the "Jump".
              SizedBox(
                height: 52, 
                width: double.infinity,
                child: authState.status == AuthStatus.loading
                    ? const Center(
                        // We center the loader inside the 52px box
                        child: SizedBox(
                          height: 24, // Smaller, tighter loader
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : Container(
                        // The Button (Already 52px via decoration, but explicitly safe here)
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFDADCE0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              ref.read(authControllerProvider.notifier).signIn();
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SvgPicture.asset(
                                      'assets/images/google.svg',
                                      height: 18,
                                      width: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.signInWithGoogle,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF3C4043),
                                        fontFamily: 'Roboto',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 34), 
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}