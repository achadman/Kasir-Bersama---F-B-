import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BulkImportService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> importProducts(String storeId) async {
    try {
      // 1. Pick File
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result == null) return {'status': 'cancelled'};

      final platformFile = result.files.single;
      final extension =
          platformFile.extension?.toLowerCase() ??
          platformFile.name.split('.').last.toLowerCase();

      List<List<dynamic>> fields = [];
      Uint8List? fileBytes;

      if (kIsWeb) {
        fileBytes = platformFile.bytes;
        if (fileBytes == null) {
          return {
            'status': 'error',
            'message': 'Gagal membaca file (Bytes null)',
          };
        }
      } else {
        if (platformFile.path != null) {
          fileBytes = await File(platformFile.path!).readAsBytes();
        }
      }

      if (fileBytes == null) {
        return {'status': 'error', 'message': 'Gagal membaca file'};
      }

      if (extension == 'csv') {
        final csvString = utf8.decode(fileBytes);
        fields = const CsvToListConverter().convert(csvString);
      } else if (extension == 'xlsx') {
        var excel = Excel.decodeBytes(fileBytes);
        var table =
            excel.tables[excel.getDefaultSheet()] ?? excel.tables.values.first;

        for (var row in table.rows) {
          fields.add(row.map((e) => e?.value).toList());
        }
      } else {
        return {
          'status': 'error',
          'message': 'Format file tidak didukung: $extension',
        };
      }

      if (fields.isEmpty) return {'status': 'error', 'message': 'File kosong'};

      // 2. Process Headers
      // Expected header: name,sku,category,buy_price,sale_price,stock_quantity,description
      final headers = fields[0]
          .map((e) => e.toString().toLowerCase().trim())
          .toList();

      int nameIdx = _findColumnIndex(headers, [
        'name',
        'nama',
        'nama produk',
        'product name',
      ]);
      int skuIdx = _findColumnIndex(headers, ['sku', 'kode', 'kode barang']);
      int categoryIdx = _findColumnIndex(headers, [
        'category',
        'kategori',
        'kategori produk',
      ]);
      int buyPriceIdx = _findColumnIndex(headers, [
        'buy_price',
        'buy price',
        'harga beli',
        'modal',
      ]);
      int salePriceIdx = _findColumnIndex(headers, [
        'sale_price',
        'sale price',
        'harga jual',
      ]);
      int stockIdx = _findColumnIndex(headers, [
        'stock_quantity',
        'stock',
        'stok',
        'jumlah stok',
      ]);
      int descIdx = _findColumnIndex(headers, [
        'description',
        'deskripsi',
        'keterangan',
      ]);

      if (nameIdx == -1) {
        return {'status': 'error', 'message': 'Kolom "name" wajib ada'};
      }

      // 3. Fetch Categories for Matching
      final catData = await supabase
          .from('categories')
          .select('id, name')
          .eq('store_id', storeId);

      Map<String, String> categoryMap = {
        for (var cat in catData)
          cat['name'].toString().toLowerCase(): cat['id'].toString(),
      };

      // 4. Parse Rows
      List<Map<String, dynamic>> productsToInsert = [];
      int successCount = 0;
      int failCount = 0;
      List<String> errors = [];

      for (int i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.isEmpty) continue;

        try {
          // Safety index check for each column
          String name = (nameIdx != -1 && nameIdx < row.length)
              ? row[nameIdx]?.toString() ?? ''
              : '';

          if (name.isEmpty) {
            failCount++;
            errors.add('Baris ${i + 1}: Nama kosong');
            continue;
          }

          String? categoryName = (categoryIdx != -1 && categoryIdx < row.length)
              ? row[categoryIdx]?.toString().toLowerCase().trim()
              : null;
          String? categoryId =
              (categoryName != null && categoryMap.containsKey(categoryName))
              ? categoryMap[categoryName]
              : null;

          productsToInsert.add({
            'store_id': storeId,
            'name': name,
            'sku': (skuIdx != -1 && skuIdx < row.length)
                ? row[skuIdx]?.toString()
                : null,
            'category_id': categoryId,
            'buy_price': _parsePrice(
              (buyPriceIdx != -1 && buyPriceIdx < row.length)
                  ? row[buyPriceIdx]
                  : 0,
            ),
            'sale_price': _parsePrice(
              (salePriceIdx != -1 && salePriceIdx < row.length)
                  ? row[salePriceIdx]
                  : 0,
            ),
            'stock_quantity': _parseInt(
              (stockIdx != -1 && stockIdx < row.length) ? row[stockIdx] : 0,
            ),
            'description': (descIdx != -1 && descIdx < row.length)
                ? row[descIdx]?.toString()
                : null,
            'is_stock_managed': true,
          });
          successCount++;
        } catch (e) {
          failCount++;
          errors.add('Baris ${i + 1}: $e');
        }
      }

      // 5. Bulk Insert
      if (productsToInsert.isNotEmpty) {
        await supabase.from('products').insert(productsToInsert);
      }

      return {
        'status': 'success',
        'successCount': successCount,
        'failCount': failCount,
        'errors': errors,
      };
    } catch (e) {
      debugPrint("Import Error: $e");
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<String?> exportProductsToExcel(String storeId) async {
    try {
      // 1. Fetch Products
      final productsData = await supabase
          .from('products')
          .select('*, categories(name)')
          .eq('store_id', storeId)
          .eq('is_deleted', false) // Only active products
          .order('name');

      if (productsData.isEmpty) {
        return null;
      }

      // 2. Create Excel
      var excel = Excel.createExcel();
      // Remove default sheet
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      Sheet sheet = excel['Products'];

      // 3. Add Headers
      // Must match Import format: name,sku,category,buy_price,sale_price,stock_quantity,description
      List<TextCellValue> headers = [
        TextCellValue('name'),
        TextCellValue('sku'),
        TextCellValue('category'),
        TextCellValue('buy_price'),
        TextCellValue('sale_price'),
        TextCellValue('stock_quantity'),
        TextCellValue('description'),
      ];
      sheet.appendRow(headers);

      // 4. Add Rows
      for (var p in productsData) {
        sheet.appendRow([
          TextCellValue(p['name'] ?? ''),
          TextCellValue(p['sku'] ?? ''),
          TextCellValue(p['categories']?['name'] ?? ''),
          IntCellValue((p['buy_price'] ?? 0).toInt()),
          IntCellValue((p['sale_price'] ?? 0).toInt()),
          IntCellValue((p['stock_quantity'] ?? 0).toInt()),
          TextCellValue(p['description'] ?? ''),
        ]);
      }

      // 5. Save File
      final String fileName =
          'products_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      var fileBytes = excel.save();

      if (fileBytes == null) {
        throw "Gagal generate file excel";
      }

      if (kIsWeb) {
        // Web: Use FileSaver to download
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          mimeType: MimeType.microsoftExcel,
        );
        return "Downloaded: $fileName";
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Mobile: Save to temp & Share
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(fileBytes);

        // Share/Open
        await Share.shareXFiles([XFile(file.path)], text: 'Export Produk');
        return "Shared: ${file.path}";
      } else {
        // Desktop: Save Dialog
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan File Excel',
          fileName: fileName,
          allowedExtensions: ['xlsx'],
          type: FileType.custom,
        );

        if (outputFile != null) {
          File(outputFile)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
          return outputFile;
        }
      }

      return null; // User cancelled
    } catch (e) {
      debugPrint("Export Error: $e");
      rethrow;
    }
  }

  int _parsePrice(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (var name in possibleNames) {
      int idx = headers.indexOf(name.toLowerCase());
      if (idx != -1) return idx;
    }
    return -1;
  }
}
