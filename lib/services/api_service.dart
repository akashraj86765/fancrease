import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static String get _baseUrl {
    if (kDebugMode && kIsWeb) {
      return 'http://localhost:8888/.netlify/functions/';
    }
    if (kDebugMode && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8888/.netlify/functions/';
    }
    return 'https://fancreaseagency.netlify.app/.netlify/functions/';
  }

  final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl));

  Future<Map<String, String>> _authHeaders() async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<double> getBalance() async {
    final response = await _dio.post(
      'smmProxy',
      data: {'action': 'balance'},
      options: Options(headers: await _authHeaders()),
    );
    return double.parse(response.data['balance'].toString());
  }

  Future<Map<String, dynamic>> addOrder({
    required int serviceId,
    required String link,
    required int quantity,
  }) async {
    final response = await _dio.post(
      'smmProxy',
      data: {
        'action': 'add',
        'service': serviceId,
        'link': link,
        'quantity': quantity,
      },
      options: Options(headers: await _authHeaders()),
    );
    return Map<String, dynamic>.from(response.data);
  }
}