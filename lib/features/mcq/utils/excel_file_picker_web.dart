import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class ExcelFileData {
  final String name;
  final List<int> bytes;

  ExcelFileData({
    required this.name,
    required this.bytes,
  });
}

Future<ExcelFileData?> pickExcelFile() async {
  final input = html.FileUploadInputElement()
    ..accept = '.xlsx,.xls'
    ..multiple = false;

  final completer = Completer<ExcelFileData?>();

  input.onChange.listen((event) async {
    try {
      final files = input.files;

      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        return;
      }

      final file = files.first;

      debugPrint('SELECTED EXCEL FILE: ${file.name}');
      debugPrint('FILE SIZE: ${file.size} bytes');

      final reader = html.FileReader();

      reader.onLoadEnd.listen((event) {
        try {
          final result = reader.result;

          if (result is ByteBuffer) {
            final bytes = Uint8List.view(result).toList();

            debugPrint('EXCEL BYTES READ: ${bytes.length}');

            if (!completer.isCompleted) {
              completer.complete(
                ExcelFileData(
                  name: file.name,
                  bytes: bytes,
                ),
              );
            }
          } else if (result is Uint8List) {
            final bytes = result.toList();

            debugPrint('EXCEL BYTES READ: ${bytes.length}');

            if (!completer.isCompleted) {
              completer.complete(
                ExcelFileData(
                  name: file.name,
                  bytes: bytes,
                ),
              );
            }
          } else {
            if (!completer.isCompleted) {
              completer.completeError(
                Exception('Unable to read Excel file bytes.'),
              );
            }
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      });

      reader.onError.listen((event) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception('Failed to read Excel file.'),
          );
        }
      });

      reader.readAsArrayBuffer(file);
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }
  });

  input.click();

  return completer.future;
}