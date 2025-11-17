import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:core_l10n/app_localizations.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final Future<void> Function(String) onScan;

  const BarcodeScannerScreen({super.key, required this.onScan});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  bool _showOverlay = false;
  late final AudioPlayer _audioPlayer;
  final _beepSound = AssetSource('audio/beep.mp3');

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? barcodeValue = barcodes.first.rawValue;

      if (barcodeValue != null && barcodeValue.isNotEmpty) {
        setState(() {
          _isProcessing = true;
          _showOverlay = true;
        });

        _audioPlayer.play(_beepSound);

        try {
          await widget.onScan(barcodeValue);
        } catch (e) {
          debugPrint("Error handling scan: $e");
        }

        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          setState(() {
            _showOverlay = false;
            _isProcessing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanBarcode),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.done, // Use l10n.done
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcodeDetect,
          ),
          if (_showOverlay)
            Container(
              color: Colors.green.withOpacity(0.5),
            ),
        ],
      ),
    );
  }
}