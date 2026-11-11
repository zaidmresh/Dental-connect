import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UploadedOrderFile {
  final String name;
  final String url;

  const UploadedOrderFile({
    required this.name,
    required this.url,
  });
}

class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<UploadedOrderFile>> pickAndUploadOrderFiles({
    required String ownerId,
    required String folder,
  }) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null) {
      return [];
    }

    final uploadedFiles = <UploadedOrderFile>[];

    for (final pickedFile in result.files) {
      final path = pickedFile.path;
      if (path == null) {
        continue;
      }

      final safeName = _safeFileName(pickedFile.name);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref =
          _storage.ref().child('$folder/$ownerId/${timestamp}_$safeName');

      await ref.putFile(File(path));
      final url = await ref.getDownloadURL();

      uploadedFiles.add(
        UploadedOrderFile(
          name: pickedFile.name,
          url: url,
        ),
      );
    }

    return uploadedFiles;
  }

  String _safeFileName(String name) {
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    if (safeName.isEmpty) {
      return 'uploaded_file';
    }
    return safeName;
  }
}
