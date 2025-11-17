import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as desktop_picker;

final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService(const Uuid(), ImagePicker());
});

class ImagePickerService {
  final Uuid _uuid;
  final ImagePicker _picker;

  ImagePickerService(this._uuid, this._picker);

  Future<String?> pickAndCopyImage(ImageSource source) async {
    XFile? pickedFile;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      pickedFile = await _picker.pickImage(source: source);
    } else if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) { // Added other desktop platforms for robustness
      if (source == ImageSource.camera) {
        return null;
      }
      final result = await desktop_picker.FilePicker.platform.pickFiles(
        type: desktop_picker.FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        pickedFile = XFile(result.files.single.path!);
      }
    }

    if (pickedFile != null) {
      final sourceFile = File(pickedFile.path);

      final appDir = await getApplicationDocumentsDirectory();
      final fileExtension = p.extension(sourceFile.path);
      final newFileName = '${_uuid.v4()}$fileExtension';
      final newPath = p.join(appDir.path, 'images', newFileName);
      final newFile = File(newPath);

      await newFile.parent.create(recursive: true);
      await sourceFile.copy(newFile.path);
      return newFile.path;
    }
    return null;
  }

  Future<void> deleteImage(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Error deleting image: $e");
    }
  }
}