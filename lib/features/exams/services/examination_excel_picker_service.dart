
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class ExaminationExcelFile {
  final String fileName;
  final Uint8List bytes;

  const ExaminationExcelFile({
    required this.fileName,
    required this.bytes,
  });
}

class ExaminationExcelPickerService {
  static Future<ExaminationExcelFile?> pickExcelFile() async {
    debugPrint('EXAM PICKER: Creating browser file input...');

    final input = html.FileUploadInputElement()
      ..accept = '.xlsx,.xls'
      ..multiple = false;

    final completer = Completer<ExaminationExcelFile?>();

    input.onChange.listen((event) {
      try {
        debugPrint('EXAM PICKER: File input changed.');

        final files = input.files;

        if (files == null || files.isEmpty) {
          debugPrint('EXAM PICKER: No file selected.');

          if (!completer.isCompleted) {
            completer.complete(null);
          }

          return;
        }

        final file = files.first;

        debugPrint(
          'EXAM PICKER: SELECTED FILE: ${file.name}',
        );

        debugPrint(
          'EXAM PICKER: FILE SIZE: ${file.size} bytes',
        );

        final reader = html.FileReader();

        reader.onLoadEnd.listen((event) {
          try {
            final result = reader.result;

            debugPrint(
              'EXAM PICKER: FILE READER RESULT TYPE: ${result.runtimeType}',
            );

            if (result == null) {
              if (!completer.isCompleted) {
                completer.completeError(
                  Exception(
                    'Unable to access the selected Excel file.',
                  ),
                );
              }

              return;
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
                'Unsupported FileReader result type: '
                '${result.runtimeType}',
              );
            }

            debugPrint(
              'EXAM PICKER: FILE BYTES READ: ${bytes.length}',
            );

            if (bytes.isEmpty) {
              throw Exception(
                'Selected Excel file is empty.',
              );
            }

            if (!completer.isCompleted) {
              completer.complete(
                ExaminationExcelFile(
                  fileName: file.name,
                  bytes: bytes,
                ),
              );
            }
          } catch (e) {
            debugPrint(
              'EXAM PICKER: FILE READER ERROR: $e',
            );

            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        });

        reader.onError.listen((event) {
          debugPrint(
            'EXAM PICKER: FILE READER ON ERROR: $event',
          );

          if (!completer.isCompleted) {
            completer.completeError(
              Exception(
                'Failed to read selected Excel file.',
              ),
            );
          }
        });

        debugPrint(
          'EXAM PICKER: STARTING FileReader.readAsArrayBuffer()...',
        );

        reader.readAsArrayBuffer(file);
      } catch (e) {
        debugPrint(
          'EXAM PICKER: CHANGE EVENT ERROR: $e',
        );

        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      }
    });

    debugPrint(
      'EXAM PICKER: Opening browser file picker...',
    );

    input.click();

    return completer.future;
  }
}
