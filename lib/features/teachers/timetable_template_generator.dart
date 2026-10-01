import 'dart:typed_data';

import 'package:excel/excel.dart';

class TimetableTemplateGenerator {
  static Uint8List generate({
    required String teacherName,
    required List<dynamic> assignments,
  }) {
    final excel = Excel.createExcel();

    final sheet = excel['Timetable'];

    // Remove default sheet if it exists and is different.
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // ---------------------------------------------------------
    // HEADER
    // ---------------------------------------------------------

    final headers = [
      'Teacher',
      'Class',
      'Section',
      'Subject',
      'Day',
      'Start Time',
      'End Time',
      'Room Number',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: i,
          rowIndex: 0,
        ),
      );

      cell.value = TextCellValue(headers[i]);

      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }

    // ---------------------------------------------------------
    // SAMPLE TIMETABLE VALUES
    // ---------------------------------------------------------

    final sampleDays = [
      'MONDAY',
      'MONDAY',
      'TUESDAY',
      'TUESDAY',
      'WEDNESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'THURSDAY',
      'FRIDAY',
      'FRIDAY',
      'SATURDAY',
      'SATURDAY',
    ];

    final sampleStartTimes = [
      '09:00',
      '10:00',
      '09:00',
      '10:00',
      '09:00',
      '10:00',
      '09:00',
      '10:00',
      '09:00',
      '10:00',
      '09:00',
      '10:00',
    ];

    final sampleEndTimes = [
      '10:00',
      '11:00',
      '10:00',
      '11:00',
      '10:00',
      '11:00',
      '10:00',
      '11:00',
      '10:00',
      '11:00',
      '10:00',
      '11:00',
    ];

    final sampleRooms = [
      '101',
      '101',
      '102',
      '102',
      '103',
      '103',
      '104',
      '104',
      '105',
      '105',
      '106',
      '106',
    ];

    // ---------------------------------------------------------
    // ASSIGNMENT DATA + SAMPLE TIMETABLE DATA
    // ---------------------------------------------------------

    for (int i = 0; i < assignments.length; i++) {
      final assignment = assignments[i];

      final rowIndex = i + 1;

      final day = sampleDays[i % sampleDays.length];
      final startTime =
          sampleStartTimes[i % sampleStartTimes.length];
      final endTime =
          sampleEndTimes[i % sampleEndTimes.length];
      final room =
          sampleRooms[i % sampleRooms.length];

      final row = [
        teacherName,
        assignment.className ?? '',
        assignment.sectionName ?? '',
        assignment.subjectName ?? '',
        day,
        startTime,
        endTime,
        room,
      ];

      for (int columnIndex = 0;
          columnIndex < row.length;
          columnIndex++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: columnIndex,
            rowIndex: rowIndex,
          ),
        );

        cell.value = TextCellValue(
          row[columnIndex].toString(),
        );

        cell.cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }
    }

    // ---------------------------------------------------------
    // COLUMN WIDTHS
    // ---------------------------------------------------------

    sheet.setColumnWidth(0, 22);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 22);
    sheet.setColumnWidth(4, 15);
    sheet.setColumnWidth(5, 15);
    sheet.setColumnWidth(6, 15);
    sheet.setColumnWidth(7, 15);

    // ---------------------------------------------------------
    // HEADER ROW HEIGHT
    // ---------------------------------------------------------

    sheet.setRowHeight(0, 25);

    // ---------------------------------------------------------
    // ENCODE
    // ---------------------------------------------------------

    final fileBytes = excel.encode();

    if (fileBytes == null) {
      throw Exception('Failed to generate Excel file.');
    }

    return Uint8List.fromList(fileBytes);
  }
}