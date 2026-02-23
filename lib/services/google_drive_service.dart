import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

class GoogleDriveService {
  static final GoogleDriveService instance = GoogleDriveService._internal();
  factory GoogleDriveService() => instance;
  GoogleDriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope, drive.DriveApi.driveAppdataScope],
  );

  GoogleSignIn get googleSignIn => _googleSignIn;
  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Initializes the service and attempts silent sign-in
  Future<void> init() async {
    _googleSignIn.onCurrentUserChanged.listen((account) async {
      _currentUser = account;
      if (account != null) {
        final client = await _googleSignIn.authenticatedClient();
        if (client != null) {
          _driveApi = drive.DriveApi(client);
        }
      } else {
        _driveApi = null;
      }
    });

    try {
      await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint("Google Drive Init Error: $e");
    }
  }

  /// Triggers the sign-in flow
  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    }
  }

  /// Signs out the user
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Uploads a file to Google Drive
  Future<String?> uploadFile(File file, {String? folderId}) async {
    if (_driveApi == null) throw "Not signed in to Google Drive";

    try {
      final String fileName = p.basename(file.path);

      // 1. Check if file already exists to update instead of duplicate
      final existingFiles = await _driveApi!.files.list(
        q: "name = '$fileName' and trashed = false",
        spaces: 'drive',
      );

      final media = drive.Media(file.openRead(), await file.length());
      final driveFile = drive.File();
      driveFile.name = fileName;

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // Update existing
        final fileId = existingFiles.files!.first.id!;
        final result = await _driveApi!.files.update(
          driveFile,
          fileId,
          uploadMedia: media,
        );
        return result.id;
      } else {
        // Create new
        if (folderId != null) {
          driveFile.parents = [folderId];
        }
        final result = await _driveApi!.files.create(
          driveFile,
          uploadMedia: media,
        );
        return result.id;
      }
    } catch (e) {
      debugPrint("Google Drive Upload Error: $e");
      rethrow;
    }
  }

  /// Searches for the latest backup file
  Future<drive.File?> findLatestBackup(String pattern) async {
    if (_driveApi == null) throw "Not signed in to Google Drive";

    try {
      final result = await _driveApi!.files.list(
        q: "name contains '$pattern' and trashed = false",
        orderBy: "createdTime desc",
        pageSize: 1,
        spaces: 'drive',
      );

      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first;
      }
      return null;
    } catch (e) {
      debugPrint("Google Drive Search Error: $e");
      rethrow;
    }
  }

  /// Downloads a file from Google Drive
  Future<File> downloadFile(String fileId, String localPath) async {
    if (_driveApi == null) throw "Not signed in to Google Drive";

    try {
      // Fetch full media for download
      final mediaResponse =
          await _driveApi!.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final List<int> dataStore = [];
      await for (final data in mediaResponse.stream) {
        dataStore.addAll(data);
      }

      final file = File(localPath);
      await file.writeAsBytes(dataStore);
      return file;
    } catch (e) {
      debugPrint("Google Drive Download Error: $e");
      rethrow;
    }
  }
}
