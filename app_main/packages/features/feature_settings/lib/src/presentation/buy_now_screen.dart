import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class BuyNowScreen extends StatelessWidget {
  const BuyNowScreen({super.key});

  Future<void> _launchPurchaseUrl(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.parse('https://mizan.app/purchase/coming-soon');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotOpenPurchasePage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.upgradeToPro),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              Icons.workspace_premium,
              size: 100,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.unlockMizanPro,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.proPrice,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '\$699 USD', // Placeholder
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.proFeatures,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            const Spacer(),
            FilledButton(
              onPressed: () => _launchPurchaseUrl(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                l10n.purchaseFullVersion,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}