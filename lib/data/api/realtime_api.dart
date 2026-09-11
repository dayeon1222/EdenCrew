import 'dart:convert';

import 'package:http/http.dart' as http;

class RealtimeApi {
  Future<Map<String, dynamic>> fetchRealtime({
    required List<String> symbols,
  }) async {
    final uri = Uri.https(
      'polling.finance.naver.com',
      '/api/realtime',
      {
        'query': 'SERVICE_ITEM:${symbols.join(',')}',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        '실시간 시세 API 요청 실패: ${response.statusCode}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}