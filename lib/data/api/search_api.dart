import 'dart:convert';

import 'package:http/http.dart' as http;

class SearchApi {
  Future<Map<String, dynamic>> searchStocks(String query) async {
    final uri = Uri.https(
      'ac.stock.naver.com',
      '/ac',
      {
        'q': query,
        'target': 'stock,ipo,index,marketindicator',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        '종목 검색 API 요청 실패: ${response.statusCode}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}