class MetadataDto {
  final String symbolCode;
  final String stockName;
  final String stockExchangeNameKor;

  MetadataDto({
    required this.symbolCode,
    required this.stockName,
    required this.stockExchangeNameKor,
  });

  factory MetadataDto.fromJson(Map<String, dynamic> json) {
    return MetadataDto(
      symbolCode: json['symbolCode'] as String,
      stockName: json['stockName'] as String,
      stockExchangeNameKor: json['stockExchangeNameKor'] as String,
    );
  }
}