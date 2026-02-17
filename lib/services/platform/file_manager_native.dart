import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

class FileManager {
  static final FileManager _instance = FileManager._internal();
  factory FileManager() => _instance;
  FileManager._internal();

  Future<String> saveFile(XFile file, String filename) async {
    final appDir = await getApplicationDocumentsDirectory();
    final localPath = p.join(appDir.path, filename);
    await file.saveTo(localPath);
    return localPath;
  }

  ImageProvider getImageProvider(String path) {
    // If it's a web URL, use NetworkImage
    if (path.startsWith('http') || path.startsWith('https')) {
      return NetworkImage(path);
    }
    // Otherwise it's a local file
    return FileImage(File(path));
  }

  Future<Uint8List?> readBytes(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  Future<String?> saveAndShareBytes(
    String filename,
    Uint8List bytes, {
    String? mimeType,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Export File'),
      );
      return file.path;
    } catch (e) {
      debugPrint("Error sharing file: $e");
      return null;
    }
  }
}
