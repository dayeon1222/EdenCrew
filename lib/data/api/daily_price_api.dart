import 'package:charset_converter/charset_converter.dart';
import 'package:http/http.dart' as http;

class DailyPriceApi {
  Future<String> fetchDailyPriceHtml({
    required String code,
    required int page,
  }) async {
    final uri = Uri.https(
      'finance.naver.com',
      '/item/sise_day.naver',
      {
        'code': code,
        'page': page.toString(),
      },
    );

    final response = await http.get(
  uri,
  headers: {
    'User-Agent': 'Mozilla/5.0',
  },
);

    if (response.statusCode != 200) {
      throw Exception(
        '일봉 API 요청 실패: ${response.statusCode}',
      );
    }

    return await CharsetConverter.decode(
      'euc-kr',
      response.bodyBytes,
    );
  }
}