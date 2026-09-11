class DailyPriceDto {
  final String localDate;
  final int closePrice;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int accumulatedTradingVolume;

  DailyPriceDto({
    required this.localDate,
    required this.closePrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedTradingVolume,
  });
}

class DailyPriceResponseDto {
  final List<DailyPriceDto> prices;
  final int lastPage;

  DailyPriceResponseDto({
    required this.prices,
    required this.lastPage,
  });
}