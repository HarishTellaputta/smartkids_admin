import 'dart:typed_data';
import 'dart:html' as html;

class ExcelDownloadService {
  static void download({
    required Uint8List bytes,
    required String fileName,
  }) {
    final blob = html.Blob(
      [
        bytes,
      ],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );

    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}