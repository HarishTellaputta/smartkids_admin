// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'package:smartkids_admin/features/attendance/models/attendance_response_model.dart';
// import 'package:smartkids_admin/features/attendance/models/attendance_update_model.dart';
// import 'package:smartkids_admin/features/attendance/services/attendance_service.dart';

// import 'package:smartkids_admin/features/teachers/models/class_model.dart';
// import 'package:smartkids_admin/features/teachers/services/class_service.dart';

// import 'package:smartkids_admin/models/student_model.dart';
// import 'package:smartkids_admin/services/student_service.dart';

// class AttendanceScreen extends StatefulWidget {
//   const AttendanceScreen({super.key});

//   @override
//   State<AttendanceScreen> createState() => _AttendanceScreenState();
// }

// class _AttendanceScreenState extends State<AttendanceScreen> {
//   AttendanceService? _attendanceService;
//   StudentService? _studentService;
//   ClassService? _classService;

//   Dio? _sectionDio;

//   DateTime selectedDate = DateTime.now();

//   List<SchoolClass> classes = [];
//   List<Student> allClassStudents = [];
//   List<Student> students = [];

//   List<SectionItem> sections = [];

//   int? selectedClassId;
//   int? selectedSectionId;

//   bool isLoading = true;
//   bool isSaving = false;
//   bool isLoadingSections = false;

//   String? errorMessage;
//   String? infoMessage;

//   String searchQuery = '';

//   final TextEditingController searchController = TextEditingController();

//   final Map<int, String> attendanceStatus = {};
//   final Map<int, AttendanceResponseModel> existingAttendance = {};
//   final Map<int, String> originalStatus = {};

//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }

//   // ============================================================
//   // INITIALIZE
//   // ============================================================

//   Future<void> _initialize() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();

//       final token = prefs.getString('jwt_token');

//       if (token == null || token.isEmpty) {
//         throw Exception('JWT token not found. Please login again.');
//       }

//       _attendanceService = AttendanceService(token);
//       _studentService = StudentService(token);
//       _classService = ClassService(token);

//       _sectionDio = Dio(
//         BaseOptions(
//           baseUrl: 'http://localhost:8080',
//           headers: {
//             'Content-Type': 'application/json',
//             'Accept': 'application/json',
//             'Authorization': 'Bearer $token',
//           },
//         ),
//       );

//       await _loadClasses();
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//         errorMessage = _cleanError(e);
//       });
//     }
//   }

//   // ============================================================
//   // LOAD CLASSES
//   // ============================================================

//   Future<void> _loadClasses() async {
//     try {
//       const int schoolId = 1;

//       final result = await _classService!.getClassesBySchool(schoolId);

//       if (!mounted) return;

//       setState(() {
//         classes = result;
//       });

//       if (classes.isEmpty) {
//         setState(() {
//           isLoading = false;
//           infoMessage = 'No classes found for this school.';
//         });
//         return;
//       }

//       selectedClassId = classes.first.id;

//       await _loadSectionsForClass();

//       await _loadAttendanceData();
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isLoading = false;
//         errorMessage = 'Failed to load classes: ${_cleanError(e)}';
//       });
//     }
//   }

//   // ============================================================
//   // LOAD SECTIONS
//   // ============================================================

//   Future<void> _loadSectionsForClass() async {
//     if (selectedClassId == null) return;

//     try {
//       setState(() {
//         isLoadingSections = true;
//         sections = [];
//         selectedSectionId = null;
//       });

//       final response = await _sectionDio!.get(
//         '/api/v1/sections/class/$selectedClassId',
//       );

//       final data = response.data;

//       final List<dynamic> list;

//       if (data is List) {
//         list = data;
//       } else {
//         list = [];
//       }

//       final loadedSections = list
//           .map((json) => SectionItem.fromJson(Map<String, dynamic>.from(json)))
//           .toList();

//       if (!mounted) return;

//       setState(() {
//         sections = loadedSections;

//         if (sections.isNotEmpty) {
//           selectedSectionId = sections.first.id;
//         } else {
//           selectedSectionId = null;
//         }

//         isLoadingSections = false;
//       });
//     } on DioException catch (e) {
//       if (!mounted) return;

//       setState(() {
//         sections = [];
//         selectedSectionId = null;
//         isLoadingSections = false;
//       });

//       debugPrint('Failed to load sections: ${e.response?.data ?? e.message}');
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         sections = [];
//         selectedSectionId = null;
//         isLoadingSections = false;
//       });

//       debugPrint('Failed to load sections: $e');
//     }
//   }

//   // ============================================================
//   // LOAD ATTENDANCE
//   // ============================================================

//   Future<void> _loadAttendanceData() async {
//     if (selectedClassId == null) return;

//     try {
//       setState(() {
//         isLoading = true;
//         errorMessage = null;
//         infoMessage = null;

//         allClassStudents = [];
//         students = [];

//         attendanceStatus.clear();
//         existingAttendance.clear();
//         originalStatus.clear();
//       });

//       // ----------------------------------------------------------
//       // 1. Load students of selected class
//       // ----------------------------------------------------------

//       final loadedStudents = await _studentService!.getStudentsByClassId(
//         selectedClassId!,
//       );

//       // ----------------------------------------------------------
//       // 2. Filter students by selected section
//       // ----------------------------------------------------------

//       List<Student> sectionStudents = loadedStudents;

//       if (selectedSectionId != null) {
//         sectionStudents = loadedStudents
//             .where((student) => student.sectionId == selectedSectionId)
//             .toList();
//       }

//       // ----------------------------------------------------------
//       // 3. Load attendance for selected class/date
//       // ----------------------------------------------------------

//       final loadedAttendance = await _attendanceService!.getClassAttendance(
//         classId: selectedClassId!,
//         date: selectedDate,
//       );

//       // ----------------------------------------------------------
//       // 4. Create attendance map
//       // ----------------------------------------------------------

//       final Map<int, AttendanceResponseModel> attendanceMap = {};

//       for (final attendance in loadedAttendance) {
//         final studentId = attendance.studentId;

//         if (studentId != null) {
//           attendanceMap[studentId] = attendance;
//         }
//       }

//       // ----------------------------------------------------------
//       // 5. If no attendance exists for this date
//       // ----------------------------------------------------------

//       if (loadedAttendance.isEmpty) {
//         if (!mounted) return;

//         setState(() {
//           allClassStudents = sectionStudents;
//           students = [];

//           attendanceStatus.clear();
//           existingAttendance.clear();
//           originalStatus.clear();

//           isLoading = false;

//           infoMessage =
//               'No attendance found for ${_formatDisplayDate(selectedDate)}.';
//         });

//         return;
//       }

//       // ----------------------------------------------------------
//       // 6. Build status maps
//       // ----------------------------------------------------------

//       final Map<int, String> statusMap = {};
//       final Map<int, String> originalMap = {};

//       for (final student in sectionStudents) {
//         final studentId = student.id;

//         if (studentId == null) continue;

//         final attendance = attendanceMap[studentId];

//         if (attendance != null) {
//           final status = _apiToUiStatus(attendance.status);

//           statusMap[studentId] = status;
//           originalMap[studentId] = status;
//         }
//       }

//       // ----------------------------------------------------------
//       // 7. Only show students who have attendance records
//       // ----------------------------------------------------------

//       final attendanceStudentIds = attendanceMap.keys.toSet();

//       final filteredStudents = sectionStudents
//           .where(
//             (student) =>
//                 student.id != null && attendanceStudentIds.contains(student.id),
//           )
//           .toList();

//       if (!mounted) return;

//       setState(() {
//         allClassStudents = sectionStudents;
//         students = filteredStudents;

//         existingAttendance
//           ..clear()
//           ..addAll(attendanceMap);

//         attendanceStatus
//           ..clear()
//           ..addAll(statusMap);

//         originalStatus
//           ..clear()
//           ..addAll(originalMap);

//         isLoading = false;
//         infoMessage = null;
//       });
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isLoading = false;

//         allClassStudents = [];
//         students = [];

//         attendanceStatus.clear();
//         existingAttendance.clear();
//         originalStatus.clear();

//         errorMessage = 'Failed to load attendance: ${_cleanError(e)}';
//       });
//     }
//   }

//   // ============================================================
//   // DATE
//   // ============================================================

//   Future<void> _selectDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2035),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.fromSeed(
//               seedColor: const Color(0xFF2563EB),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked == null) return;

//     setState(() {
//       selectedDate = picked;
//     });

//     await _loadAttendanceData();
//   }

//   // ============================================================
//   // CLASS CHANGE
//   // ============================================================

//   Future<void> _onClassChanged(int? classId) async {
//     if (classId == null) return;

//     setState(() {
//       selectedClassId = classId;
//       selectedSectionId = null;

//       sections = [];

//       errorMessage = null;
//       infoMessage = null;
//     });

//     await _loadSectionsForClass();

//     await _loadAttendanceData();
//   }

//   // ============================================================
//   // SECTION CHANGE
//   // ============================================================

//   Future<void> _onSectionChanged(int? sectionId) async {
//     setState(() {
//       selectedSectionId = sectionId;
//     });

//     await _loadAttendanceData();
//   }

//   // ============================================================
//   // SEARCH
//   // ============================================================

//   List<Student> get filteredStudents {
//     final query = searchQuery.toLowerCase().trim();

//     if (query.isEmpty) {
//       return students;
//     }

//     return students.where((student) {
//       final name = student.name?.toLowerCase() ?? '';
//       final admissionNo = student.admissionNo?.toLowerCase() ?? '';
//       final id = student.id?.toString() ?? '';

//       return name.contains(query) ||
//           admissionNo.contains(query) ||
//           id.contains(query);
//     }).toList();
//   }

//   void _onSearchChanged(String value) {
//     setState(() {
//       searchQuery = value;
//     });
//   }

//   // ============================================================
//   // ATTENDANCE STATUS
//   // ============================================================

//   void _changeAttendance(Student student, String status) {
//     final studentId = student.id;

//     if (studentId == null) return;

//     setState(() {
//       attendanceStatus[studentId] = status;
//     });
//   }

//   // ============================================================
//   // SAVE
//   // ============================================================

//   Future<void> _saveChanges() async {
//     if (isSaving) return;

//     final changedStudents = students.where((student) {
//       final studentId = student.id;

//       if (studentId == null) return false;

//       final current = attendanceStatus[studentId];
//       final original = originalStatus[studentId];

//       return current != null && original != null && current != original;
//     }).toList();

//     if (changedStudents.isEmpty) {
//       _showInfo('No attendance changes to save.');
//       return;
//     }

//     setState(() {
//       isSaving = true;
//       errorMessage = null;
//     });

//     try {
//       /*
//        * IMPORTANT:
//        *
//        * Current backend AttendanceUpdateDto requires teacherId.
//        *
//        * Since Teacher dropdown has been removed, we temporarily use
//        * the original markedByTeacherId for the existing attendance
//        * record.
//        *
//        * This allows the current backend contract to process the update,
//        * but the backend should later be changed so the actual logged-in
//        * admin/teacher is recorded as updatedBy.
//        */

//       for (final student in changedStudents) {
//         final studentId = student.id!;

//         final attendance = existingAttendance[studentId];

//         if (attendance == null) continue;

//         final teacherId = attendance.markedByTeacherId;

//         if (teacherId == null) {
//           throw Exception(
//             'Attendance record ${attendance.id} does not have a markedByTeacherId.',
//           );
//         }

//         final newStatus = attendanceStatus[studentId] ?? 'Present';

//         final request = AttendanceUpdateModel(
//           teacherId: teacherId,
//           status: _uiToApiStatus(newStatus),
//           remarks: attendance.remarks,
//         );

//         await _attendanceService!.updateAttendance(attendance.id!, request);
//       }

//       if (!mounted) return;

//       setState(() {
//         for (final student in changedStudents) {
//           final studentId = student.id!;

//           final current = attendanceStatus[studentId];

//           if (current != null) {
//             originalStatus[studentId] = current;
//           }
//         }

//         isSaving = false;
//       });

//       _showSuccess(
//         '${changedStudents.length} attendance record'
//         '${changedStudents.length == 1 ? '' : 's'} updated successfully.',
//       );

//       await _loadAttendanceData();
//     } catch (e) {
//       if (!mounted) return;

//       setState(() {
//         isSaving = false;
//       });

//       _showError('Failed to save attendance: ${_cleanError(e)}');
//     }
//   }

//   // ============================================================
//   // STATUS MAPPING
//   // ============================================================

//   String _apiToUiStatus(String? status) {
//     switch ((status ?? '').toUpperCase()) {
//       case 'PRESENT':
//         return 'Present';

//       case 'ABSENT':
//         return 'Absent';

//       case 'LEAVE':
//         return 'Leave';

//       default:
//         return 'Present';
//     }
//   }

//   String _uiToApiStatus(String status) {
//     switch (status) {
//       case 'Present':
//         return 'PRESENT';

//       case 'Absent':
//         return 'ABSENT';

//       case 'Leave':
//         return 'LEAVE';

//       default:
//         return 'PRESENT';
//     }
//   }

//   // ============================================================
//   // COUNTS
//   // ============================================================

//   int get presentCount {
//     return students.where((student) {
//       final id = student.id;
//       return id != null && attendanceStatus[id] == 'Present';
//     }).length;
//   }

//   int get absentCount {
//     return students.where((student) {
//       final id = student.id;
//       return id != null && attendanceStatus[id] == 'Absent';
//     }).length;
//   }

//   int get leaveCount {
//     return students.where((student) {
//       final id = student.id;
//       return id != null && attendanceStatus[id] == 'Leave';
//     }).length;
//   }

//   int get totalCount {
//     return students.length;
//   }

//   double get attendancePercentage {
//     if (totalCount == 0) return 0;

//     return (presentCount / totalCount) * 100;
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FB),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         surfaceTintColor: Colors.white,
//         titleSpacing: 24,
//         title: const Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Attendance',
//               style: TextStyle(
//                 color: Color(0xFF111827),
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             SizedBox(height: 2),
//             Text(
//               'Manage and review daily student attendance',
//               style: TextStyle(
//                 color: Color(0xFF6B7280),
//                 fontSize: 12,
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 24),
//             child: _buildSaveButton(),
//           ),
//         ],
//       ),
//       body: isLoading && classes.isEmpty
//           ? const Center(child: CircularProgressIndicator())
//           : _buildBody(theme),
//     );
//   }

//   // ============================================================
//   // BODY
//   // ============================================================

//   Widget _buildBody(ThemeData theme) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final isMobile = constraints.maxWidth < 700;

//         return SingleChildScrollView(
//           padding: EdgeInsets.all(isMobile ? 16 : 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildPageHeader(isMobile),
//               const SizedBox(height: 20),

//               _buildControls(isMobile),
//               const SizedBox(height: 20),

//               if (errorMessage != null) _buildErrorCard(),

//               if (infoMessage != null) _buildInfoCard(),

//               if (isLoading)
//                 const Padding(
//                   padding: EdgeInsets.symmetric(vertical: 60),
//                   child: Center(child: CircularProgressIndicator()),
//                 )
//               else ...[
//                 if (students.isNotEmpty) ...[
//                   _buildSummaryCards(isMobile),
//                   const SizedBox(height: 24),
//                   _buildAttendanceSection(),
//                 ] else if (errorMessage == null && infoMessage == null) ...[
//                   _buildEmptyState(),
//                 ],
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // ============================================================
//   // PAGE HEADER
//   // ============================================================

//   Widget _buildPageHeader(bool isMobile) {
//     final className = _selectedClassName();

//     final sectionName = selectedSectionId == null
//         ? null
//         : sections
//               .where((section) => section.id == selectedSectionId)
//               .map((section) => section.name)
//               .firstOrNull;

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       child: isMobile
//           ? Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHeaderIcon(),
//                 const SizedBox(height: 14),
//                 _buildContextText(className, sectionName),
//               ],
//             )
//           : Row(
//               children: [
//                 _buildHeaderIcon(),
//                 const SizedBox(width: 14),
//                 Expanded(child: _buildContextText(className, sectionName)),
//                 _buildDateBadge(),
//               ],
//             ),
//     );
//   }

//   Widget _buildHeaderIcon() {
//     return Container(
//       width: 48,
//       height: 48,
//       decoration: BoxDecoration(
//         color: const Color(0xFFEFF6FF),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: const Icon(
//         Icons.fact_check_outlined,
//         color: Color(0xFF2563EB),
//         size: 26,
//       ),
//     );
//   }

//   Widget _buildContextText(String className, String? sectionName) {
//     final sectionText = sectionName == null ? '' : ' • Section $sectionName';

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           '$className$sectionText',
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w700,
//             color: Color(0xFF111827),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           _formatDisplayDate(selectedDate),
//           style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
//         ),
//       ],
//     );
//   }

//   Widget _buildDateBadge() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF9FAFB),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(
//             Icons.calendar_today_outlined,
//             size: 17,
//             color: Color(0xFF2563EB),
//           ),
//           const SizedBox(width: 8),
//           Text(
//             _formatDisplayDate(selectedDate),
//             style: const TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF374151),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // CONTROLS
//   // ============================================================

//   Widget _buildControls(bool isMobile) {
//     if (isMobile) {
//       return Column(
//         children: [
//           _dateSelector(),
//           const SizedBox(height: 12),
//           _classSelector(),
//           if (sections.isNotEmpty) ...[
//             const SizedBox(height: 12),
//             _sectionSelector(),
//           ],
//           const SizedBox(height: 12),
//           _searchBox(),
//         ],
//       );
//     }

//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SizedBox(width: 190, child: _dateSelector()),
//         const SizedBox(width: 12),
//         SizedBox(width: 210, child: _classSelector()),
//         if (sections.isNotEmpty) ...[
//           const SizedBox(width: 12),
//           SizedBox(width: 190, child: _sectionSelector()),
//         ],
//         const SizedBox(width: 12),
//         Expanded(child: _searchBox()),
//       ],
//     );
//   }

//   // ============================================================
//   // DATE SELECTOR
//   // ============================================================

//   Widget _dateSelector() {
//     return _controlContainer(
//       child: InkWell(
//         onTap: _selectDate,
//         borderRadius: BorderRadius.circular(10),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//           child: Row(
//             children: [
//               const Icon(
//                 Icons.calendar_month_outlined,
//                 size: 19,
//                 color: Color(0xFF2563EB),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Date',
//                       style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       _formatDisplayDate(selectedDate),
//                       style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF111827),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const Icon(
//                 Icons.keyboard_arrow_down,
//                 size: 20,
//                 color: Color(0xFF6B7280),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // CLASS SELECTOR
//   // ============================================================

//   Widget _classSelector() {
//     return _controlContainer(
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<int>(
//           value: selectedClassId,
//           isExpanded: true,
//           icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
//           hint: const Text('Select class'),
//           items: classes
//               .where((item) => item.id != null)
//               .map(
//                 (item) => DropdownMenuItem<int>(
//                   value: item.id,
//                   child: Text(
//                     item.name ?? 'Class ${item.id}',
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               )
//               .toList(),
//           onChanged: _onClassChanged,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // SECTION SELECTOR
//   // ============================================================

//   Widget _sectionSelector() {
//     if (isLoadingSections) {
//       return _controlContainer(
//         child: const SizedBox(
//           height: 40,
//           child: Row(
//             children: [
//               SizedBox(
//                 width: 18,
//                 height: 18,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//               SizedBox(width: 10),
//               Text(
//                 'Loading sections...',
//                 style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return _controlContainer(
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<int>(
//           value: selectedSectionId,
//           isExpanded: true,
//           icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
//           hint: const Text('Select section'),
//           items: sections
//               .where((section) => section.id != null)
//               .map(
//                 (section) => DropdownMenuItem<int>(
//                   value: section.id,
//                   child: Text(
//                     'Section ${section.name}',
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               )
//               .toList(),
//           onChanged: _onSectionChanged,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // SEARCH
//   // ============================================================

//   Widget _searchBox() {
//     return _controlContainer(
//       child: TextField(
//         controller: searchController,
//         onChanged: _onSearchChanged,
//         decoration: const InputDecoration(
//           border: InputBorder.none,
//           isDense: true,
//           hintText: 'Search student by name, admission number...',
//           hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
//           prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF6B7280)),
//           prefixIconConstraints: BoxConstraints(minWidth: 42),
//         ),
//       ),
//     );
//   }

//   Widget _controlContainer({required Widget child}) {
//     return Container(
//       constraints: const BoxConstraints(minHeight: 60),
//       padding: const EdgeInsets.symmetric(horizontal: 4),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       child: child,
//     );
//   }

//   // ============================================================
//   // SUMMARY CARDS
//   // ============================================================

//   Widget _buildSummaryCards(bool isMobile) {
//     final cards = [
//       _SummaryData(
//         title: 'Total Students',
//         value: '$totalCount',
//         icon: Icons.groups_outlined,
//       ),
//       _SummaryData(
//         title: 'Present',
//         value: '$presentCount',
//         icon: Icons.check_circle_outline,
//       ),
//       _SummaryData(
//         title: 'Absent',
//         value: '$absentCount',
//         icon: Icons.cancel_outlined,
//       ),
//       _SummaryData(
//         title: 'Leave',
//         value: '$leaveCount',
//         icon: Icons.event_busy_outlined,
//       ),
//       _SummaryData(
//         title: 'Attendance',
//         value: '${attendancePercentage.toStringAsFixed(1)}%',
//         icon: Icons.analytics_outlined,
//       ),
//     ];

//     if (isMobile) {
//       return Column(
//         children: cards
//             .map(
//               (card) => Padding(
//                 padding: const EdgeInsets.only(bottom: 10),
//                 child: _summaryCard(card),
//               ),
//             )
//             .toList(),
//       );
//     }

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final width = (constraints.maxWidth - 40) / 5;

//         return Row(
//           children: cards
//               .map(
//                 (card) => SizedBox(
//                   width: width,
//                   child: Padding(
//                     padding: const EdgeInsets.only(right: 10),
//                     child: _summaryCard(card),
//                   ),
//                 ),
//               )
//               .toList(),
//         );
//       },
//     );
//   }

//   Widget _summaryCard(_SummaryData data) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: const Color(0xFFF3F4F6),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(data.icon, size: 21, color: const Color(0xFF374151)),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   data.title,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 11,
//                     color: Color(0xFF6B7280),
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   data.value,
//                   style: const TextStyle(
//                     fontSize: 19,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF111827),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // ATTENDANCE SECTION
//   // ============================================================

//   Widget _buildAttendanceSection() {
//     final visibleStudents = filteredStudents;

//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildAttendanceSectionHeader(visibleStudents.length),
//           const Divider(height: 1, color: Color(0xFFE5E7EB)),
//           if (visibleStudents.isEmpty)
//             _buildSearchEmptyState()
//           else
//             _buildAttendanceTable(visibleStudents),
//         ],
//       ),
//     );
//   }

//   Widget _buildAttendanceSectionHeader(int visibleCount) {
//     return Padding(
//       padding: const EdgeInsets.all(18),
//       child: Row(
//         children: [
//           const Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Student Attendance',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                     color: Color(0xFF111827),
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   'Review or correct attendance for the selected date',
//                   style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//             decoration: BoxDecoration(
//               color: const Color(0xFFF3F4F6),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text(
//               '$visibleCount students',
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF374151),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // TABLE
//   // ============================================================

//   Widget _buildAttendanceTable(List<Student> visibleStudents) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: DataTable(
//         headingRowHeight: 48,
//         dataRowMinHeight: 72,
//         dataRowMaxHeight: 82,
//         columnSpacing: 30,
//         horizontalMargin: 18,
//         headingTextStyle: const TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.w700,
//           color: Color(0xFF6B7280),
//         ),
//         columns: const [
//           DataColumn(label: Text('ROLL NO.')),
//           DataColumn(label: Text('STUDENT')),
//           DataColumn(label: Text('STATUS')),
//           DataColumn(label: Text('MARKED BY')),
//           DataColumn(label: Text('MARK ATTENDANCE')),
//         ],
//         rows: visibleStudents.map((student) {
//           final studentId = student.id!;

//           final status = attendanceStatus[studentId] ?? 'Present';

//           final attendance = existingAttendance[studentId];

//           return DataRow(
//             cells: [
//               DataCell(
//                 Text(
//                   student.admissionNo?.isNotEmpty == true
//                       ? student.admissionNo!
//                       : '-',
//                   style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF374151),
//                   ),
//                 ),
//               ),
//               DataCell(_buildStudentCell(student)),
//               DataCell(_statusBadge(status)),
//               DataCell(_buildMarkedByCell(attendance)),
//               DataCell(_attendanceButtons(student, status)),
//             ],
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildStudentCell(Student student) {
//     return SizedBox(
//       width: 190,
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 19,
//             backgroundColor: const Color(0xFFEFF6FF),
//             child: Text(
//               _initials(student.name),
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w700,
//                 color: Color(0xFF2563EB),
//               ),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   student.name ?? 'Unknown Student',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF111827),
//                   ),
//                 ),
//                 if (student.sectionName != null)
//                   Text(
//                     'Section ${student.sectionName}',
//                     style: const TextStyle(
//                       fontSize: 11,
//                       color: Color(0xFF9CA3AF),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMarkedByCell(AttendanceResponseModel? attendance) {
//     if (attendance == null ||
//         attendance.markedByTeacherName == null ||
//         attendance.markedByTeacherName!.trim().isEmpty) {
//       return const Text(
//         '-',
//         style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
//       );
//     }

//     return SizedBox(
//       width: 130,
//       child: Row(
//         children: [
//           const Icon(Icons.person_outline, size: 17, color: Color(0xFF6B7280)),
//           const SizedBox(width: 6),
//           Expanded(
//             child: Text(
//               attendance.markedByTeacherName!,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 fontSize: 12,
//                 color: Color(0xFF374151),
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // ATTENDANCE BUTTONS
//   // ============================================================

//   Widget _attendanceButtons(Student student, String currentStatus) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         _statusButton(
//           student: student,
//           label: 'P',
//           status: 'Present',
//           currentStatus: currentStatus,
//         ),
//         const SizedBox(width: 6),
//         _statusButton(
//           student: student,
//           label: 'A',
//           status: 'Absent',
//           currentStatus: currentStatus,
//         ),
//         const SizedBox(width: 6),
//         _statusButton(
//           student: student,
//           label: 'L',
//           status: 'Leave',
//           currentStatus: currentStatus,
//         ),
//       ],
//     );
//   }

//   Widget _statusButton({
//     required Student student,
//     required String label,
//     required String status,
//     required String currentStatus,
//   }) {
//     final selected = currentStatus == status;

//     return Tooltip(
//       message: status,
//       child: InkWell(
//         onTap: () {
//           _changeAttendance(student, status);
//         },
//         borderRadius: BorderRadius.circular(8),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 150),
//           width: 38,
//           height: 34,
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             color: selected ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: selected
//                   ? const Color(0xFF111827)
//                   : const Color(0xFFE5E7EB),
//             ),
//           ),
//           child: Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w700,
//               color: selected ? Colors.white : const Color(0xFF6B7280),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // STATUS BADGE
//   // ============================================================

//   Widget _statusBadge(String status) {
//     IconData icon;

//     switch (status) {
//       case 'Present':
//         icon = Icons.check_circle_outline;
//         break;

//       case 'Absent':
//         icon = Icons.cancel_outlined;
//         break;

//       case 'Leave':
//         icon = Icons.event_busy_outlined;
//         break;

//       default:
//         icon = Icons.help_outline;
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
//       decoration: BoxDecoration(
//         color: _statusBackground(status),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 15, color: _statusColor(status)),
//           const SizedBox(width: 5),
//           Text(
//             status,
//             style: TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w700,
//               color: _statusColor(status),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _statusColor(String status) {
//     switch (status) {
//       case 'Present':
//         return const Color(0xFF15803D);

//       case 'Absent':
//         return const Color(0xFFDC2626);

//       case 'Leave':
//         return const Color(0xFFD97706);

//       default:
//         return const Color(0xFF6B7280);
//     }
//   }

//   Color _statusBackground(String status) {
//     switch (status) {
//       case 'Present':
//         return const Color(0xFFECFDF3);

//       case 'Absent':
//         return const Color(0xFFFEF2F2);

//       case 'Leave':
//         return const Color(0xFFFFFBEB);

//       default:
//         return const Color(0xFFF3F4F6);
//     }
//   }

//   // ============================================================
//   // EMPTY STATE
//   // ============================================================

//   Widget _buildEmptyState() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       child: const Column(
//         children: [
//           Icon(Icons.people_outline, size: 48, color: Color(0xFF9CA3AF)),
//           SizedBox(height: 14),
//           Text(
//             'No students found',
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w700,
//               color: Color(0xFF374151),
//             ),
//           ),
//           SizedBox(height: 6),
//           Text(
//             'There are no students matching the selected class and section.',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchEmptyState() {
//     return const Padding(
//       padding: EdgeInsets.symmetric(vertical: 50, horizontal: 20),
//       child: Column(
//         children: [
//           Icon(Icons.search_off_outlined, size: 42, color: Color(0xFF9CA3AF)),
//           SizedBox(height: 12),
//           Text(
//             'No matching students',
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.w700,
//               color: Color(0xFF374151),
//             ),
//           ),
//           SizedBox(height: 5),
//           Text(
//             'Try a different name or admission number.',
//             style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // ERROR / INFO
//   // ============================================================

//   Widget _buildErrorCard() {
//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 20),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: const Color(0xFFFEF2F2),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFFECACA)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               errorMessage!,
//               style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoCard() {
//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.only(bottom: 20),
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: const Color(0xFFEFF6FF),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: const Color(0xFFBFDBFE)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Icon(Icons.info_outline, color: Color(0xFF2563EB)),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               infoMessage!,
//               style: const TextStyle(
//                 fontSize: 13,
//                 color: Color(0xFF1E40AF),
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // SAVE BUTTON
//   // ============================================================

//   Widget _buildSaveButton() {
//     return ElevatedButton.icon(
//       onPressed: isSaving || isLoading ? null : _saveChanges,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: const Color(0xFF2563EB),
//         foregroundColor: Colors.white,
//         disabledBackgroundColor: const Color(0xFFCBD5E1),
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         elevation: 0,
//       ),
//       icon: isSaving
//           ? const SizedBox(
//               width: 16,
//               height: 16,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 color: Colors.white,
//               ),
//             )
//           : const Icon(Icons.save_outlined, size: 18),
//       label: Text(
//         isSaving ? 'Saving...' : 'Save Changes',
//         style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
//       ),
//     );
//   }

//   // ============================================================
//   // HELPERS
//   // ============================================================

//   String _selectedClassName() {
//     if (selectedClassId == null) {
//       return 'No class selected';
//     }

//     for (final item in classes) {
//       if (item.id == selectedClassId) {
//         return item.name ?? 'Class $selectedClassId';
//       }
//     }

//     return 'Class $selectedClassId';
//   }

//   String _formatDisplayDate(DateTime date) {
//     const months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec',
//     ];

//     return '${date.day.toString().padLeft(2, '0')} '
//         '${months[date.month - 1]} '
//         '${date.year}';
//   }

//   String _initials(String? name) {
//     if (name == null || name.trim().isEmpty) {
//       return '?';
//     }

//     final parts = name.trim().split(RegExp(r'\s+'));

//     if (parts.length == 1) {
//       return parts.first
//           .substring(0, parts.first.length >= 2 ? 2 : 1)
//           .toUpperCase();
//     }

//     return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
//   }

//   String _cleanError(Object error) {
//     if (error is DioException) {
//       final responseData = error.response?.data;

//       if (responseData is Map && responseData['message'] != null) {
//         return responseData['message'].toString();
//       }

//       if (responseData is String && responseData.isNotEmpty) {
//         return responseData;
//       }

//       return error.message ?? 'Network error occurred.';
//     }

//     return error.toString().replaceFirst('Exception: ', '');
//   }

//   void _showSuccess(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: const Color(0xFF15803D),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   void _showInfo(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: const Color(0xFF2563EB),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   void _showError(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: const Color(0xFFDC2626),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }
// }

// // ================================================================
// // SECTION MODEL
// // ================================================================

// class SectionItem {
//   final int? id;
//   final int? classId;
//   final String? className;
//   final String? name;
//   final int? capacity;
//   final String? description;
//   final String? createdAt;
//   final String? updatedAt;

//   SectionItem({
//     this.id,
//     this.classId,
//     this.className,
//     this.name,
//     this.capacity,
//     this.description,
//     this.createdAt,
//     this.updatedAt,
//   });

//   factory SectionItem.fromJson(Map<String, dynamic> json) {
//     return SectionItem(
//       id: json['id'],
//       classId: json['classId'],
//       className: json['className'],
//       name: json['name'],
//       capacity: json['capacity'],
//       description: json['description'],
//       createdAt: json['createdAt'],
//       updatedAt: json['updatedAt'],
//     );
//   }
// }

// // ================================================================
// // SUMMARY MODEL
// // ================================================================

// class _SummaryData {
//   final String title;
//   final String value;
//   final IconData icon;

//   const _SummaryData({
//     required this.title,
//     required this.value,
//     required this.icon,
//   });
// }

// // ================================================================
// // EXTENSION
// // ================================================================

// extension FirstOrNullExtension<T> on Iterable<T> {
//   T? get firstOrNull {
//     if (isEmpty) return null;
//     return first;
//   }
// }
