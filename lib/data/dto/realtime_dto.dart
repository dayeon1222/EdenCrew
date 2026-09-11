class RealtimeResponseDto {
  final String resultCode;
  final List<RealtimeItemDto> items;

  RealtimeResponseDto({
    required this.resultCode,
    required this.items,
  });

  factory RealtimeResponseDto.fromJson(Map<String, dynamic> json) {
    final areas = json['result']['areas'] as List;

    final items = areas
        .expand((area) => area['datas'] as List)
        .map(
          (item) => RealtimeItemDto.fromJson(item),
        )
        .toList();

    return RealtimeResponseDto(
      resultCode: json['resultCode'] as String,
      items: items,
    );
  }
}

class RealtimeItemDto {
  final String code;
  final int currentPrice;
  final int previousClosePrice;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int accumulatedVolume;
  final int listedStockCount;

  RealtimeItemDto({
    required this.code,
    required this.currentPrice,
    required this.previousClosePrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedVolume,
    required this.listedStockCount,
  });

  factory RealtimeItemDto.fromJson(Map<String, dynamic> json) {
    return RealtimeItemDto(
      code: json['cd'] as String,
      currentPrice: json['nv'] as int,
      previousClosePrice: json['pcv'] as int,
      openPrice: json['ov'] as int,
      highPrice: json['hv'] as int,
      lowPrice: json['lv'] as int,
      accumulatedVolume: json['aq'] as int,
      listedStockCount: json['countOfListedStock'] as int,
    );
  }
}