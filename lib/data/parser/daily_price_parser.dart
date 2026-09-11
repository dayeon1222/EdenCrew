import 'package:html/parser.dart' as html_parser;

import '../dto/daily_price_dto.dart';

DailyPriceResponseDto parseDailyPrices(String html) {
  final document = html_parser.parse(html);

  final rows = document.querySelectorAll('table.type2 tr');

  final prices = <DailyPriceDto>[];

  for (final row in rows) {
    final cells = row.querySelectorAll('td');

    if (cells.length < 7) {
      continue;
    }

    final date = cells[0].text.trim();

    if (!RegExp(r'^\d{4}\.\d{2}\.\d{2}$').hasMatch(date)) {
      continue;
    }

    final closePrice = _parseNumber(cells[1].text);
    final openPrice = _parseNumber(cells[3].text);
    final highPrice = _parseNumber(cells[4].text);
    final lowPrice = _parseNumber(cells[5].text);
    final volume = _parseNumber(cells[6].text);

    prices.add(
      DailyPriceDto(
        localDate: date.replaceAll('.', ''),
        closePrice: closePrice,
        openPrice: openPrice,
        highPrice: highPrice,
        lowPrice: lowPrice,
        accumulatedTradingVolume: volume,
      ),
    );
  }

  final lastPage = _parseLastPage(document);

  return DailyPriceResponseDto(
    prices: prices,
    lastPage: lastPage,
  );
}

int _parseLastPage(dynamic document) {
  final lastPageLink = document.querySelector('td.pgRR a');

  if (lastPageLink == null) {
    throw Exception('마지막 페이지 정보를 찾을 수 없습니다.');
  }

  final href = lastPageLink.attributes['href'];

  if (href == null) {
    throw Exception('마지막 페이지 링크를 찾을 수 없습니다.');
  }

  final uri = Uri.parse(href);
  final page = uri.queryParameters['page'];

  if (page == null) {
    throw Exception('마지막 페이지 번호를 찾을 수 없습니다.');
  }

  return int.parse(page);
}

int _parseNumber(String value) {
  return int.parse(value.replaceAll(',', '').trim());
}