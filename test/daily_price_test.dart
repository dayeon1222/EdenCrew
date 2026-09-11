import 'package:edencrew_assignment_starter/data/parser/daily_price_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('일봉 HTML 파싱 테스트', () {
    const html = '''
      <table class="type2">
        <tr>
          <td>2026.09.11</td>
          <td>259,500</td>
          <td>950</td>
          <td>258,000</td>
          <td>261,500</td>
          <td>256,500</td>
          <td>13,938,673</td>
        </tr>
        <tr>
          <td>2026.09.10</td>
          <td>269,000</td>
          <td>1,000</td>
          <td>270,000</td>
          <td>267,000</td>
          <td>266,000</td>
          <td>12,000,000</td>
        </tr>
      </table>

      <table class="Nnavi">
        <tr>
          <td class="pgRR">
            <a href="/item/sise_day.naver?code=005930&amp;page=756">
              마지막
            </a>
          </td>
        </tr>
      </table>
    ''';

    final result = parseDailyPrices(html);

    expect(result.prices.length, 2);

    expect(result.prices[0].localDate, '20260911');
    expect(result.prices[0].closePrice, 259500);
    expect(result.prices[0].openPrice, 258000);
    expect(result.prices[0].highPrice, 261500);
    expect(result.prices[0].lowPrice, 256500);
    expect(result.prices[0].accumulatedTradingVolume, 13938673);

    expect(result.lastPage, 756);
  });
}