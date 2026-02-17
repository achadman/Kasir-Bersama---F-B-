import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:restart_app/restart_app.dart';
import 'package:share_plus/share_plus.dart';
import '../app_database.dart'; // Adjusted path

class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  /// Creates a full backup (DB + Images) as a ZIP file.
  Future<String?> createFullBackup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(appDir.path, 'db.sqlite');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        throw "Database file not found at $dbPath";
      }

      // 1. Create Staging Directory
      final tempDir = await getTemporaryDirectory();
      final stagingDirName =
          'backup_staging_${DateTime.now().millisecondsSinceEpoch}';
      final stagingDir = Directory(p.join(tempDir.path, stagingDirName));
      if (await stagingDir.exists()) {
        await stagingDir.delete(recursive: true);
      }
      await stagingDir.create();

      // 2. Copy Database to Staging
      await dbFile.copy(p.join(stagingDir.path, 'db.sqlite'));

      // 3. Copy Images to Staging/images
      final imagesDir = Directory(p.join(stagingDir.path, 'images'));
      await imagesDir.create();

      final Set<String> uniqueImagePaths = {};

      // Helper to collect paths
      void collect(String? path) {
        if (path != null && path.isNotEmpty && !path.startsWith('http')) {
          uniqueImagePaths.add(path);
        }
      }

      // Query DB for image paths
      final products = await _db.select(_db.products).get();
      for (var p in products) collect(p.imageUrl);

      final stores = await _db.select(_db.stores).get();
      for (var s in stores) collect(s.logoUrl);

      final profiles = await _db.select(_db.profiles).get();
      for (var u in profiles) collect(u.avatarUrl);

      final attendance = await _db.select(_db.attendanceLogs).get();
      for (var a in attendance) collect(a.photoUrl);

      int copiedCount = 0;
      for (var path in uniqueImagePaths) {
        final file = File(path);
        if (await file.exists()) {
          // We copy the file into images/filename.ext
          // On restore, we'll strip the old absolute path prefix and replace with new one.
          final filename = p.basename(path);
          await file.copy(p.join(imagesDir.path, filename));
          copiedCount++;
        }
      }
      debugPrint("Backup: Copied $copiedCount images.");

      // 4. Create ZIP
      final zipPath = p.join(
        tempDir.path,
        'pos_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
      );
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      encoder.addDirectory(
        stagingDir,
        includeDirName: false,
      ); // Add contents of staging to root of zip
      encoder.close();

      // Cleanup Staging
      await stagingDir.delete(recursive: true);

      // Share
      final xFile = XFile(zipPath);
      await Share.shareXFiles([xFile], text: 'POS Kasir Asri Full Backup');

      return zipPath;
    } catch (e) {
      debugPrint("Create Backup Error: $e");
      rethrow;
    }
  }

  /// Restores a full backup from a ZIP file and RESTARTS the app.
  Future<void> restoreFullBackup(String zipPath) async {
    try {
      final zipFile = File(zipPath);
      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();

      // 1. Unzip to Staging
      final stagingDir = Directory(
        p.join(
          tempDir.path,
          'restore_staging_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      if (await stagingDir.exists()) await stagingDir.delete(recursive: true);
      await stagingDir.create();

      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File(p.join(stagingDir.path, filename))
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(p.join(stagingDir.path, filename)).create(recursive: true);
        }
      }

      // 2. Locate db.sqlite in Staging
      File? newDbFile;
      Directory? newImagesDir;

      // Check root
      final rootDb = File(p.join(stagingDir.path, 'db.sqlite'));
      if (await rootDb.exists()) {
        newDbFile = rootDb;
        newImagesDir = Directory(p.join(stagingDir.path, 'images'));
      } else {
        // Check 1 level deep (if zipped with folder)
        await for (var entity in stagingDir.list()) {
          if (entity is Directory) {
            final subDb = File(p.join(entity.path, 'db.sqlite'));
            if (await subDb.exists()) {
              newDbFile = subDb;
              newImagesDir = Directory(p.join(entity.path, 'images'));
              break;
            }
          }
        }
      }

      if (newDbFile == null) {
        throw "Invalid Backup: db.sqlite not found in zip.";
      }

      // 3. OVERWRITE DATABASE
      // Close current DB to release locks
      await _db.close();

      final targetDbPath = p.join(appDir.path, 'db.sqlite');
      // Adding a small delay to ensure file handle release?
      await Future.delayed(const Duration(milliseconds: 500));

      if (await File(targetDbPath).exists()) {
        await File(targetDbPath).delete();
      }
      await newDbFile.copy(targetDbPath);

      // 4. RESTORE IMAGES
      if (newImagesDir != null && await newImagesDir.exists()) {
        await for (var img in newImagesDir.list()) {
          if (img is File) {
            final filename = p.basename(img.path);
            // Copy to App Documents Root (where FileManager creates files)
            await img.copy(p.join(appDir.path, filename));
          }
        }
      }

      // 5. FIX IMAGE PATHS (Critical for cross-device restore)
      // Open the restored DB temporarily to update paths
      final tempDb = NativeDatabase(File(targetDbPath));
      final executor = tempDb;
      await executor.ensureOpen(_QueryExecutorUser());

      try {
        // We need to update paths in: Products, Stores, Profiles, AttendanceLogs
        // Helper to update a table
        Future<void> fixTable(
          String tableName,
          String colName,
          String idCol,
        ) async {
          // Select all rows where column is not null
          final result = await executor.runSelect(
            'SELECT $idCol, $colName FROM $tableName WHERE $colName IS NOT NULL',
            [],
          );

          for (final row in result) {
            final id = row[idCol];
            final oldPath = row[colName] as String;

            // Skip http/https URLs
            if (oldPath.toLowerCase().startsWith('http')) continue;

            final filename = p.basename(oldPath);
            final newPath = p.join(appDir.path, filename);

            if (oldPath != newPath) {
              await executor.runUpdate(
                'UPDATE $tableName SET $colName = ? WHERE $idCol = ?',
                [newPath, id],
              );
            }
          }
        }

        await fixTable('products', 'image_url', 'id');
        await fixTable('stores', 'logo_url', 'id');
        await fixTable('stores', 'admin_avatar', 'id');
        await fixTable('profiles', 'avatar_url', 'id');
        await fixTable('attendance_logs', 'photo_url', 'id');

        debugPrint("Restore: Image paths updated successfully.");
      } catch (e) {
        debugPrint("Restore: Failed to update image paths: $e");
        // Don't fail the whole restore, just log.
        // Images might be broken but data is there.
      } finally {
        await executor.close();
      }

      // Cleanup
      await stagingDir.delete(recursive: true);

      // RESTART
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        // Desktop platforms might not support restart_app
        // Just return, the UI will show success message/dialog
      } else {
        await Restart.restartApp();
      }
    } catch (e) {
      debugPrint("Restore Error: $e");
      rethrow;
    }
  }
}

class _QueryExecutorUser extends QueryExecutorUser {
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
  @override
  int get schemaVersion => 3;
}
