import 'package:dio/dio.dart';
import 'package:smartkids_admin/models/student_model.dart';

class StudentService {
  final Dio dio;

  StudentService(String token)
    : dio = Dio(
        BaseOptions(
          baseUrl: 'http://localhost:8080',
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    print('========================================');
    print('STUDENT SERVICE CREATED');
    print('BASE URL: ${dio.options.baseUrl}');
    print('AUTHORIZATION: ${dio.options.headers['Authorization']}');
    print('CONTENT TYPE: ${dio.options.headers['Content-Type']}');
    print('========================================');
  }

  // =========================
  // GET STUDENTS
  // =========================

  Future<StudentPage> getStudents({
    int page = 0,
    int size = 10,
    String sortBy = 'id',
    String sortDirection = 'asc',
  }) async {
    print('');
    print('========================================');
    print('GET STUDENTS STARTED');
    print('========================================');

    print('REQUEST URL: ${dio.options.baseUrl}/students');

    print('QUERY PARAMETERS:');
    print('page: $page');
    print('size: $size');
    print('sortBy: $sortBy');
    print('sortDirection: $sortDirection');

    print('AUTH HEADER: ${dio.options.headers['Authorization']}');

    try {
      final response = await dio.get(
        '/api/v1/students',
        queryParameters: {
          'page': page,
          'size': size,
          'sortBy': sortBy,
          'sortDirection': sortDirection,
        },
      );

      print('');
      print('========== STUDENT API RESPONSE ==========');
      print('STATUS CODE: ${response.statusCode}');
      print('STATUS MESSAGE: ${response.statusMessage}');
      print('RESPONSE DATA:');
      print(response.data);
      print('==========================================');

      final studentPage = StudentPage.fromJson(response.data);

      print('');
      print('========== PARSED STUDENT DATA ==========');
      print('CONTENT LENGTH: ${studentPage.content.length}');
      print('TOTAL ELEMENTS: ${studentPage.totalElements}');
      print('TOTAL PAGES: ${studentPage.totalPages}');
      print('CURRENT PAGE: ${studentPage.number}');
      print('=========================================');

      return studentPage;
    } on DioException catch (e) {
      print('');
      print('!!!!!!!! STUDENT API ERROR !!!!!!!!');
      print('ERROR TYPE: ${e.type}');
      print('ERROR MESSAGE: ${e.message}');
      print('REQUEST URL: ${e.requestOptions.uri}');
      print('REQUEST METHOD: ${e.requestOptions.method}');
      print('REQUEST HEADERS: ${e.requestOptions.headers}');
      print('STATUS CODE: ${e.response?.statusCode}');
      print('RESPONSE DATA: ${e.response?.data}');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');

      rethrow;
    } catch (e, stackTrace) {
      print('');
      print('!!!!!!!! STUDENT PARSING ERROR !!!!!!!!');
      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');

      rethrow;
    }
  }

  // =========================
  // GET STUDENT BY ID
  // =========================

  Future<Student> getStudent(int id) async {
    print('');
    print('========================================');
    print('GET STUDENT BY ID');
    print('STUDENT ID: $id');
    print('========================================');

    try {
      final response = await dio.get('/api/v1/students/$id');

      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE DATA: ${response.data}');

      final student = Student.fromJson(response.data);

      print('STUDENT PARSED SUCCESSFULLY');
      print('STUDENT ID: ${student.id}');
      print('STUDENT NAME: ${student.name}');

      return student;
    } on DioException catch (e) {
      print('!!!!!!!! GET STUDENT ERROR !!!!!!!!');
      print('ERROR: ${e.message}');
      print('STATUS: ${e.response?.statusCode}');
      print('DATA: ${e.response?.data}');

      rethrow;
    }
  }

  // =========================
  // CREATE STUDENT
  // =========================

  Future<Student> createStudent(Map<String, dynamic> data) async {
    print('');
    print('========================================');
    print('CREATE STUDENT');
    print('REQUEST DATA: $data');
    print('========================================');

    try {
      final response = await dio.post('/api/v1/students', data: data);

      print('CREATE STATUS: ${response.statusCode}');
      print('CREATE RESPONSE: ${response.data}');

      final student = Student.fromJson(response.data);

      print('STUDENT CREATED');
      print('ID: ${student.id}');
      print('NAME: ${student.name}');

      return student;
    } on DioException catch (e) {
      print('!!!!!!!! CREATE STUDENT ERROR !!!!!!!!');
      print('ERROR: ${e.message}');
      print('STATUS: ${e.response?.statusCode}');
      print('DATA: ${e.response?.data}');

      rethrow;
    }
  }

  // =========================
  // UPDATE STUDENT
  // =========================

  Future<Student> updateStudent(int id, Map<String, dynamic> data) async {
    print('');
    print('========================================');
    print('UPDATE STUDENT');
    print('ID: $id');
    print('REQUEST DATA: $data');
    print('========================================');

    try {
      final response = await dio.put('/api/v1/students/$id', data: data);

      print('UPDATE STATUS: ${response.statusCode}');
      print('UPDATE RESPONSE: ${response.data}');

      final student = Student.fromJson(response.data);

      print('STUDENT UPDATED');
      print('ID: ${student.id}');
      print('NAME: ${student.name}');

      return student;
    } on DioException catch (e) {
      print('!!!!!!!! UPDATE STUDENT ERROR !!!!!!!!');
      print('ERROR: ${e.message}');
      print('STATUS: ${e.response?.statusCode}');
      print('DATA: ${e.response?.data}');

      rethrow;
    }
  }

  // =========================
  // DELETE STUDENT
  // =========================

  Future<void> deleteStudent(int id) async {
    print('');
    print('========================================');
    print('DELETE STUDENT');
    print('ID: $id');
    print('========================================');

    try {
      final response = await dio.delete('/api/v1/students/$id');

      print('DELETE STATUS: ${response.statusCode}');
      print('DELETE RESPONSE: ${response.data}');

      print('STUDENT DELETED SUCCESSFULLY');
    } on DioException catch (e) {
      print('!!!!!!!! DELETE STUDENT ERROR !!!!!!!!');
      print('ERROR: ${e.message}');
      print('STATUS: ${e.response?.statusCode}');
      print('DATA: ${e.response?.data}');

      rethrow;
    }
  }

  // =========================
  // GET STUDENTS BY CLASS
  // =========================

  Future<List<Student>> getStudentsByClassId(int classId) async {
    print('');
    print('========================================');
    print('GET STUDENTS BY CLASS');
    print('CLASS ID: $classId');
    print('========================================');

    try {
      final response = await dio.get('/api/v1/students/class/$classId');

      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE DATA: ${response.data}');

      final data = response.data;

      if (data is List) {
        final students = data
            .map((json) => Student.fromJson(Map<String, dynamic>.from(json)))
            .toList();

        print('STUDENTS FOUND: ${students.length}');

        return students;
      }

      return [];
    } on DioException catch (e) {
      print('!!!!!!!! GET STUDENTS BY CLASS ERROR !!!!!!!!');
      print('ERROR: ${e.message}');
      print('STATUS: ${e.response?.statusCode}');
      print('DATA: ${e.response?.data}');

      rethrow;
    } catch (e) {
      print('!!!!!!!! STUDENT PARSING ERROR !!!!!!!!');
      print('ERROR: $e');

      rethrow;
    }
  }
}
