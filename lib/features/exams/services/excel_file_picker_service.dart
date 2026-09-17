
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class ExcelFileData {
  final String fileName;
  final Uint8List bytes;

  const ExcelFileData({
    required this.fileName,
    required this.bytes,
  });
}

class ExcelFilePickerService {
  static Future<ExcelFileData?> pickExcelFile() async {
    debugPrint('EXCEL PICKER: Creating browser file input...');

    final input = html.FileUploadInputElement()
      ..accept = '.xlsx,.xls'
      ..multiple = false;

    final completer = Completer<ExcelFileData?>();

    input.onChange.listen((event) {
      try {
        final files = input.files;

        if (files == null || files.isEmpty) {
          debugPrint('EXCEL PICKER: No file selected.');

          if (!completer.isCompleted) {
            completer.complete(null);
          }
          return;
        }

        final file = files.first;

        debugPrint('EXCEL PICKER: SELECTED FILE: ${file.name}');
        debugPrint('EXCEL PICKER: FILE SIZE: ${file.size} bytes');

        final reader = html.FileReader();

        reader.onLoadEnd.listen((event) {
          try {
            final result = reader.result;

            debugPrint(
              'EXCEL PICKER: RESULT TYPE: ${result.runtimeType}',
            );

            if (result == null) {
              throw Exception(
                'Unable to access the selected Excel file.',
              );
            }

            Uint8List bytes;

            if (result is ByteBuffer) {
              bytes = Uint8List.view(result);
            } else if (result is Uint8List) {
              bytes = result;
            } else if (result is List<int>) {
              bytes = Uint8List.fromList(result);
            } else {
              throw Exception(
                'Unsupported file reader result type: '
                '${result.runtimeType}',
              );
            }

            debugPrint(
              'EXCEL PICKER: FILE BYTES READ: ${bytes.length}',
            );

            if (bytes.isEmpty) {
              throw Exception('Selected Excel file is empty.');
            }

            if (!completer.isCompleted) {
              completer.complete(
                ExcelFileData(
                  fileName: file.name,
                  bytes: bytes,
                ),
              );
            }
          } catch (e) {
            debugPrint('EXCEL PICKER ERROR: $e');

            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        });

        reader.onError.listen((event) {
          if (!completer.isCompleted) {
            completer.completeError(
              Exception(
                'Failed to read selected Excel file.',
              ),
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
}
