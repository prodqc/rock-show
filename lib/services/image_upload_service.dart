import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ImageUploadService {
  static final _storage = FirebaseStorage.instance;
  static final _picker = ImagePicker();
  static const _uuid = Uuid();

  /// Pick from gallery and upload. Returns download URL or null.
  static Future<String?> pickAndUpload({
    required String folder, // e.g. 'venues', 'shows', 'avatars'
    int maxWidth = 1200,
    int quality = 80,
  }) async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth.toDouble(),
      imageQuality: quality,
    );
    if (xfile == null) return null;
    return uploadFile(File(xfile.path), folder: folder);
  }

  /// Upload a File and return the download URL.
  static Future<String> uploadFile(
    File file, {
    required String folder,
  }) async {
    final ext = file.path.split('.').last;
    final ref = _storage.ref('$folder/${_uuid.v4()}.$ext');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/$ext'),
    );
    return ref.getDownloadURL();
  }

  /// Delete a file by its download URL.
  static Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}