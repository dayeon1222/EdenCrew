import 'dart:async'; 
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../widgets/custom_toast.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 디바운스 및 로딩 상태 추가
  Timer? _debounce;
  bool _isLoading = false;

  // 검색어 상태
  String _query = '';

  // 임시 데이터 (실제 프로젝트에서는 Provider / ViewModel로 관리)
  final List<Map<String, dynamic>> _mockStocks = [
    {'name': '삼성전자', 'symbol': '005930', 'exchange': '코스피', 'isFavorite': true},
    {'name': '삼성전자우', 'symbol': '005935', 'exchange': '코스피', 'isFavorite': false},
    {'name': '삼성바이오로직스', 'symbol': '207940', 'exchange': '코스피', 'isFavorite': false},
    {'name': '삼성에스디에스', 'symbol': '018260', 'exchange': '코스피', 'isFavorite': false},
    {'name': '삼성중공업', 'symbol': '010140', 'exchange': '코스피', 'isFavorite': false},
    {'name': '삼성물산', 'symbol': '028260', 'exchange': '코스피', 'isFavorite': false},
    {'name': 'SK하이닉스', 'symbol': '000660', 'exchange': '코스피', 'isFavorite': false},
    {'name': '카카오', 'symbol': '035720', 'exchange': '코스피', 'isFavorite': false},
  ];

  @override
  void initState() {
    super.initState();
    // 디바운스 처리(300ms) 적용
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final text = _searchController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _query = '';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _query = text;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Timer 해제
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // 관심 등록 토글 및 토스트 메시지 함수
  void _toggleFavorite(Map<String, dynamic> stock) {
    final isFavorite = stock['isFavorite'] as bool;

    setState(() {
      stock['isFavorite'] = !isFavorite;
    });

    final newStatus = stock['isFavorite'] as bool;

    CustomToast.show(
      context,
      message: newStatus ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
      icon: newStatus ? Icons.star : Icons.star_border,
      iconColor: newStatus
          ? context.colors.favoriteActive
          : (context.colors.favoriteInactive ?? context.colors.textSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 검색 결과 필터링
    final filteredResults = _query.isEmpty
        ? <Map<String, dynamic>>[]
        : _mockStocks.where((stock) {
            final name = stock['name'] as String;
            final symbol = stock['symbol'] as String;
            return name.contains(_query) || symbol.contains(_query);
          }).toList();

    return Scaffold(
      backgroundColor: context.colors.surfaceBase,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar Area
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.dimens.space4,
                vertical: context.dimens.space2 ?? 8,
              ),
              child: _buildSearchBar(context),
            ),
            
            // 2. Body Section (Initial / Results / No Results)
            Expanded(
              child: _query.isEmpty
                  ? _buildInitialState(context)
                  : filteredResults.isNotEmpty
                      ? _buildSearchResults(context, filteredResults)
                      : _buildNoResultsState(context),
            ),
          ],
        ),
      ),
    );
  }

  /// 상단 검색 바
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(context.dimens.radiusMd ?? 8),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.dimens.space3 ?? 12,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: context.colors.textSecondary,
            size: 20,
          ),
          SizedBox(width: context.dimens.space2 ?? 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 15,
              ),
              cursorColor: context.colors.textPrimary,
              decoration: InputDecoration(
                hintText: '종목명 또는 종목코드',
                hintStyle: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // 입력 중 로딩 상태 및 지우기 버튼 추가
          if (_isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colors.textSecondary,
              ),
            )
          else if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
              },
              child: Icon(
                Icons.close,
                color: context.colors.textSecondary,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  /// 초기 검색 대기 상태 (종목을 검색해 보세요)
  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 56,
            color: context.colors.textDisabled,
          ),
          SizedBox(height: context.dimens.space4),
          Text(
            '종목을 검색해 보세요',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.dimens.space2 ?? 8),
          Text(
            '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 검색 결과 목록
  Widget _buildSearchResults(
    BuildContext context,
    List<Map<String, dynamic>> results,
  ) {
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => Divider(
        color: context.colors.borderSubtle ?? context.colors.surfaceRaised,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final stock = results[index];
        final name = stock['name'] as String;
        final symbol = stock['symbol'] as String;
        final exchange = stock['exchange'] as String;
        final isFavorite = stock['isFavorite'] as bool;

        return ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.dimens.space4,
            vertical: context.dimens.space1 ?? 4,
          ),
          title: _buildHighlightedText(
            context,
            text: name,
            query: _query,
          ),
          subtitle: Text(
            '$symbol · $exchange',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: GestureDetector(
            onTap: () => _toggleFavorite(stock), // 토스트 및 상태 전환 함수 연결
            child: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              // 관심종목 활성화 시 강조 컬러(또는 노란색 계열), 비활성화 시 textSecondary
              color: isFavorite
                ? context.colors.favoriteActive
                : (context.colors.favoriteInactive ?? context.colors.textSecondary),
            ),
          ),
          onTap: () {
            // 종목 상세 화면 이동 처리
          },
        );
      },
    );
  }

  /// 검색 결과 없음 상태
  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.dimens.space6 ?? 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // X 표시가 겹쳐진 돋보기 아이콘 스타일
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 56,
                  color: context.colors.textDisabled,
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: context.colors.textDisabled,
                  ),
                ),
              ],
            ),
            SizedBox(height: context.dimens.space4),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: context.dimens.space2 ?? 8),
            // 긴 검색어 오버플로우 방지 처리
            Text(
              '\'$_query\'와\n일치하는 검색 결과를 찾지 못했습니다.',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 검색어 일치 영역 하이라이팅 처리 (예: '삼성' 강조)
  Widget _buildHighlightedText(
    BuildContext context, {
    required String text,
    required String query,
  }) {
    if (query.isEmpty || !text.contains(query)) {
      return Text(
        text,
        style: TextStyle(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    }

    final startIndex = text.indexOf(query);
    final endIndex = startIndex + query.length;

    final beforeMatch = text.substring(0, startIndex);
    final match = text.substring(startIndex, endIndex);
    final afterMatch = text.substring(endIndex);

    final highlightColor = context.colors.searchHighlight;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontFamily: 'NotoSansKR',
        ),
        children: [
          if (beforeMatch.isNotEmpty) TextSpan(text: beforeMatch),
          TextSpan(
            text: match,
            style: TextStyle(color: highlightColor),
          ),
          if (afterMatch.isNotEmpty) TextSpan(text: afterMatch),
        ],
      ),
    );
  }
}