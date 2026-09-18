import 'package:dio/dio.dart';

/// Creates a mock Dio Response with success auth data.
Response<Map<String, dynamic>> mockLoginSuccessResponse({
  required String token,
  required Map<String, dynamic> userJson,
}) {
  return Response<Map<String, dynamic>>(
    requestOptions: RequestOptions(path: '/auth/login'),
    statusCode: 200,
    data: {
      'success': true,
      'message': 'Login berhasil.',
      'data': {'token': token, 'token_type': 'Bearer', 'user': userJson},
      'meta': null,
    },
  );
}

/// Creates a mock Dio Response for /auth/me.
Response<Map<String, dynamic>> mockMeSuccessResponse({
  required Map<String, dynamic> userJson,
}) {
  return Response<Map<String, dynamic>>(
    requestOptions: RequestOptions(path: '/auth/me'),
    statusCode: 200,
    data: {'success': true, 'message': 'OK', 'data': userJson},
  );
}

/// Creates a mock 204 Response for logout.
Response<void> mockLogout204Response() {
  return Response<void>(
    requestOptions: RequestOptions(path: '/auth/logout'),
    statusCode: 204,
  );
}
