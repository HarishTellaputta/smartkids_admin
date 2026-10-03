import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedExcelFile {
  final String name;
  final Uint8List bytes;

  const PickedExcelFile({
    required this.name,
    required this.bytes,
  });
}

class ExcelFilePicker {
  ExcelFilePicker._();

  static Future<PickedExcelFile?> pick() async {
    print('========================================');
    print('EXCEL FILE PICKER STARTED');
    print('========================================');

    final input = html.FileUploadInputElement();

    // FileUploadInputElement is already a file input.
    input.accept =
        '.xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    input.multiple = false;
    input.style.display = 'none';

    html.document.body?.append(input);

    final completer = Completer<html.File?>();

    late StreamSubscription<html.Event> changeSubscription;
    late StreamSubscription<html.Event> errorSubscription;

    changeSubscription = input.onChange.listen((event) {
      print('FILE INPUT CHANGE EVENT FIRED');

      final files = input.files;

      if (files == null || files.isEmpty) {
        print('NO FILE SELECTED');

        if (!completer.isCompleted) {
          completer.complete(null);
        }

        return;
      }

      final file = files.first;

      print('FILE SELECTED: ${file.name}');
      print('FILE SIZE: ${file.size}');

      if (!completer.isCompleted) {
        completer.complete(file);
      }
    });

    errorSubscription = input.onError.listen((event) {
      print('FILE INPUT ERROR');

      if (!completer.isCompleted) {
        completer.completeError(
          Exception(
            'Unable to open the file picker.',
          ),
        );
      }
    });

    try {
      print('OPENING BROWSER FILE PICKER...');

      input.click();

      final file = await completer.future;

      print('BROWSER FILE PICKER COMPLETED');

      if (file == null) {
        print('NO FILE SELECTED / USER CANCELLED');
        return null;
      }

      print('SELECTED FILE: ${file.name}');
      print('FILE SIZE: ${file.size}');

      if (!file.name.toLowerCase().endsWith('.xlsx')) {
        throw Exception(
          'Please select an .xlsx Excel file.',
        );
      }

      // ============================================================
      // READ FILE
      // ============================================================

      final reader = html.FileReader();

      final bytesCompleter =
          Completer<Uint8List>();

      late StreamSubscription<html.ProgressEvent>
          loadSubscription;

      late StreamSubscription<html.ProgressEvent>
          readerErrorSubscription;

      loadSubscription =
          reader.onLoad.listen((event) {
        try {
          print(
            'FILE READER LOAD EVENT FIRED',
          );

          final result = reader.result;

          if (result is ByteBuffer) {
            final bytes =
                Uint8List.view(result);

            if (!bytesCompleter.isCompleted) {
              bytesCompleter.complete(bytes);
            }
          } else if (result is Uint8List) {
            if (!bytesCompleter.isCompleted) {
              bytesCompleter.complete(result);
            }
          } else {
            if (!bytesCompleter.isCompleted) {
              bytesCompleter.completeError(
                Exception(
                  'Unable to read the selected Excel file.',
                ),
              );
            }
          }
        } catch (e) {
          if (!bytesCompleter.isCompleted) {
            bytesCompleter.completeError(e);
          }
        }
      });

      readerErrorSubscription =
          reader.onError.listen((event) {
        print('FILE READER ERROR');

        if (!bytesCompleter.isCompleted) {
          bytesCompleter.completeError(
            Exception(
              'Unable to read the selected Excel file.',
            ),
          );
        }
      });

      try {
        print('READING EXCEL FILE...');

        reader.readAsArrayBuffer(file);

        final bytes =
            await bytesCompleter.future;

        print(
          'FILE BYTES: ${bytes.length}',
        );

        if (bytes.isEmpty) {
          throw Exception(
            'Unable to read the selected Excel file.',
          );
        }

        print('EXCEL FILE PICKER SUCCESS');
        print(
          '========================================',
        );

        return PickedExcelFile(
          name: file.name,
          bytes: bytes,
        );
      } finally {
        await loadSubscription.cancel();
        await readerErrorSubscription.cancel();
      }
    } catch (e) {
      print(
        '========================================',
      );
      print('EXCEL FILE PICKER ERROR');
      print('$e');
      print(
        '========================================',
      );

      rethrow;
    } finally {
      await changeSubscription.cancel();
      await errorSubscription.cancel();

      input.remove();

      print('FILE INPUT CLEANED');
    }
  }
}