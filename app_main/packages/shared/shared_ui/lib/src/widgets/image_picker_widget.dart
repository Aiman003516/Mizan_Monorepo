import 'dart:io';
import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart'; // UPDATED import

class ImagePickerWidget extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const ImagePickerWidget({
    super.key,
    required this.imagePath,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Column(
      children: [
        // --- Image Display ---
        Container(
          height: 150,
          width: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    // Handle file read errors
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.error_outline,
                        color: Colors.red.shade400,
                        size: 48,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.image_not_supported,
                  color: Colors.grey.shade500,
                  size: 48,
                ),
        ),
        const SizedBox(height: 16),

        // --- Buttons ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasImage)
              TextButton.icon(
                icon: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                label: Text(
                  l10n.removeImage,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onPressed: onRemoveImage,
              ),
            const SizedBox(width: 16),
            FilledButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(
                  hasImage ? l10n.changeImage : l10n.uploadImage),
              onPressed: onPickImage,
            ),
          ],
        ),
      ],
    );
  }
}