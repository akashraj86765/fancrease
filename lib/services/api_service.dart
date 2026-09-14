import 'dart:convert';
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

  Map<String, dynamic> _parseMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw Exception('Unexpected response type: ${data.runtimeType}');
  }

  Future<double> getBalance() async {
    final response = await _dio.post(
      'smmProxy',
      data: {'action': 'balance'},
      options: Options(headers: await _authHeaders()),
    );
    final map = _parseMap(response.data);
    return double.parse(map['balance'].toString());
  }

  Future<Map<String, dynamic>> addOrder({
    required int serviceId,
    required String link,
    required int quantity,
  }) async {
    try {
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
      return _parseMap(response.data);
    } on DioException catch (e) {
      final body = e.response?.data;
      String message = 'Order failed';
      if (body is Map && body['error'] != null) {
        message = body['error'].toString();
      } else if (body is String) {
        message = body;
      } else if (e.message != null) {
        message = e.message!;
      }
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> submitDeposit({
    required double amount,
    required String utrNumber,
    String? proofUrl,
  }) async {
    try {
      final response = await _dio.post(
        'submitDeposit',
        data: {
          'amount': amount,
          'utr_number': utrNumber,
          'proof_url': proofUrl,
        },
        options: Options(headers: await _authHeaders()),
      );
      return _parseMap(response.data);
    } on DioException catch (e) {
      final body = e.response?.data;
      String message = 'Deposit failed';
      if (body is Map && body['error'] != null) {
        message = body['error'].toString();
      } else if (body is String) {
        message = body;
      }
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> reviewDeposit({
    required int transactionId,
    required String action, // 'approve' or 'reject'
    String? adminNote,
  }) async {
    try {
      final response = await _dio.post(
        'reviewDeposit',
        data: {
          'transaction_id': transactionId,
          'action': action,
          'admin_note': adminNote,
        },
        options: Options(headers: await _authHeaders()),
      );
      return _parseMap(response.data);
    } on DioException catch (e) {
      final body = e.response?.data;
      String message = 'Action failed';
      if (body is Map && body['error'] != null) {
        message = body['error'].toString();
      }
      throw Exception(message);
    }
  }
}