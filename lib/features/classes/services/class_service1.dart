// import 'package:dio/dio.dart';
// import '../models/class_model.dart';

// class ClassService {
//   final Dio _dio;

//   ClassService(String token)
//       : _dio = Dio(
//           BaseOptions(
//             baseUrl: 'http://localhost:8080',
//             headers: {
//               'Authorization': 'Bearer $token',
//               'Content-Type': 'application/json',
//             },
//           ),
//         );

//   // GET /api/v1/classes
//   Future<List<ClassModel>> getAllClasses() async {
//     try {
//       final response = await _dio.get('/api/v1/classes');

//       final List<dynamic> data = response.data;

//       return data
//           .map((json) => ClassModel.fromJson(json))
//           .toList();
//     } on DioException catch (e) {
//       throw Exception(
//         e.response?.data?.toString() ??
//             e.message ??
//             'Failed to load classes',
//       );
//     }
//   }

//   // GET /api/v1/classes/school/{schoolId}
//   Future<List<ClassModel>> getClassesBySchool(int schoolId) async {
//     try {
//       final response = await _dio.get(
//         '/api/v1/classes/school/$schoolId',
//       );

//       final List<dynamic> data = response.data;

//       return data
//           .map((json) => ClassModel.fromJson(json))
//           .toList();
//     } on DioException catch (e) {
//       throw Exception(
//         e.response?.data?.toString() ??
//             e.message ??
//             'Failed to load school classes',
//       );
//     }
//   }

//   // GET /api/v1/classes/{id}
//   Future<ClassModel> getClassById(int id) async {
//     try {
//       final response = await _dio.get(
//         '/api/v1/classes/$id',
//       );

//       return ClassModel.fromJson(response.data);
//     } on DioException catch (e) {
//       throw Exception(
//         e.response?.data?.toString() ??
//             e.message ??
//             'Failed to load class',
//       );
//     }
//   }

//   // POST /api/v1/classes
//   // Future<ClassModel> createClass(ClassModel classModel) async {
//   //   try {
//   //     final response = await _dio.post(
//   //       '/api/v1/classes',
//   //       data: classModel.toJson(),
//   //     );

//   //     return ClassModel.fromJson(response.data);
//   //   } on DioException catch (e) {
//   //     throw Exception(
//   //       e.response?.data?.toString() ??
//   //           e.message ??
//   //           'Failed to create class',
//   //     );
//   //   }
//   // }

//   // PUT /api/v1/classes/{id}
//   // Future<ClassModel> updateClass(
//   //   int id,
//   //   ClassModel classModel,
//   // ) async {
//   //   try {
//   //     final response = await _dio.put(
//   //       '/api/v1/classes/$id',
//   //       data: classModel.toJson(),
//   //     );

//   //     return ClassModel.fromJson(response.data);
//   //   } on DioException catch (e) {
//   //     throw Exception(
//   //       e.response?.data?.toString() ??
//   //           e.message ??
//   //           'Failed to update class',
//   //     );
//   //   }
//   // }

//   // DELETE /api/v1/classes/{id}
//   Future<void> deleteClass(int id) async {
//     try {
//       await _dio.delete(
//         '/api/v1/classes/$id',
//       );
//     } on DioException catch (e) {
//       throw Exception(
//         e.response?.data?.toString() ??
//             e.message ??
//             'Failed to delete class',
//       );
//     }
//   }
// }