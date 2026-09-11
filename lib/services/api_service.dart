import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://fancreaseagency.netlify.app/.netlify/functions/',
  ));

  Future<List<dynamic>> getServices() async {
    final response = await _dio.post('smmProxy', data: {
      'action': 'services',
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getBalance() async {
    final response = await _dio.post('smmProxy', data: {
      'action': 'balance',
    });
    return response.data;
  }

  Future<Map<String, dynamic>> addOrder({
    required int serviceId,
    required String link,
    required int quantity,
  }) async {
    final response = await _dio.post('smmProxy', data: {
      'action': 'add',
      'service': serviceId,
      'link': link,
      'quantity': quantity,
    });
    return response.data;
  }
}