class SearchResponseDto {
  final String query;
  final List<SearchItemDto> items;

  SearchResponseDto({
    required this.query,
    required this.items,
  });

  factory SearchResponseDto.fromJson(Map<String, dynamic> json) {
    return SearchResponseDto(
      query: json['query'] as String,
      items: (json['items'] as List)
          .map((item) => SearchItemDto.fromJson(item))
          .toList(),
    );
  }
}

class SearchItemDto {
  final String code;
  final String name;
  final String typeCode;
  final String typeName;
  final String url;
  final String reutersCode;
  final String nationCode;
  final String nationName;
  final String category;
  final bool hasDiscussion;

  SearchItemDto({
    required this.code,
    required this.name,
    required this.typeCode,
    required this.typeName,
    required this.url,
    required this.reutersCode,
    required this.nationCode,
    required this.nationName,
    required this.category,
    required this.hasDiscussion,
  });

  factory SearchItemDto.fromJson(Map<String, dynamic> json) {
    return SearchItemDto(
      code: json['code'] as String,
      name: json['name'] as String,
      typeCode: json['typeCode'] as String,
      typeName: json['typeName'] as String,
      url: json['url'] as String,
      reutersCode: json['reutersCode'] as String,
      nationCode: json['nationCode'] as String,
      nationName: json['nationName'] as String,
      category: json['category'] as String,
      hasDiscussion: json['hasDiscussion'] as bool,
    );
  }
}