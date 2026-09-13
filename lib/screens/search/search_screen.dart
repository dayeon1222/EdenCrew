import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api/search_api.dart';
import '../../data/dto/search_dto.dart';
import '../../providers/watchlist_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/custom_toast.dart';
import '../detail/stock_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const String _recentSearchesKey =
      'recent_searches';

  static const int _maxRecentSearches = 10;

  final TextEditingController _searchController =
      TextEditingController();

  final FocusNode _focusNode =
      FocusNode();

  final SearchApi _searchApi =
      SearchApi();

  Timer? _debounce;

  bool _isLoading = false;

  String _query = '';

  List<Map<String, dynamic>> _searchResults = [];

  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _onSearchChanged,
    );

    _loadRecentSearches();
  }

  // ------------------------------------------
  // 최근 검색어 불러오기
  // ------------------------------------------

  Future<void> _loadRecentSearches() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final saved =
          prefs.getStringList(
        _recentSearchesKey,
      );

      if (!mounted) return;

      setState(() {
        _recentSearches =
            saved ?? [];
      });
    } catch (e) {
      debugPrint(
        '최근 검색어 불러오기 실패: $e',
      );
    }
  }

  // ------------------------------------------
  // 최근 검색어 저장
  // ------------------------------------------

  Future<void> _saveRecentSearch(
    String query,
  ) async {
    final normalizedQuery =
        query.trim();

    if (normalizedQuery.isEmpty) {
      return;
    }

    final updated =
        List<String>.from(
      _recentSearches,
    );

    // 기존 동일 검색어 제거
    updated.removeWhere(
      (item) =>
          item == normalizedQuery,
    );

    // 최신 검색어를 맨 앞에 추가
    updated.insert(
      0,
      normalizedQuery,
    );

    // 최대 10개
    if (updated.length >
        _maxRecentSearches) {
      updated.removeRange(
        _maxRecentSearches,
        updated.length,
      );
    }

    if (mounted) {
      setState(() {
        _recentSearches = updated;
      });
    }

    try {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setStringList(
        _recentSearchesKey,
        updated,
      );
    } catch (e) {
      debugPrint(
        '최근 검색어 저장 실패: $e',
      );
    }
  }

  // ------------------------------------------
  // 최근 검색어 하나 삭제
  // ------------------------------------------

  Future<void> _removeRecentSearch(
    String query,
  ) async {
    final updated =
        List<String>.from(
      _recentSearches,
    );

    updated.remove(query);

    if (mounted) {
      setState(() {
        _recentSearches = updated;
      });
    }

    try {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setStringList(
        _recentSearchesKey,
        updated,
      );
    } catch (e) {
      debugPrint(
        '최근 검색어 삭제 실패: $e',
      );
    }
  }

  // ------------------------------------------
  // 최근 검색어 전체 삭제
  // ------------------------------------------

  Future<void> _clearRecentSearches() async {
    if (mounted) {
      setState(() {
        _recentSearches = [];
      });
    }

    try {
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.remove(
        _recentSearchesKey,
      );
    } catch (e) {
      debugPrint(
        '최근 검색어 전체 삭제 실패: $e',
      );
    }
  }

  // ------------------------------------------
  // 검색어 입력
  // ------------------------------------------

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    final text =
        _searchController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _query = '';
        _searchResults = [];
        _isLoading = false;
      });

      return;
    }

    setState(() {
      _query = text;
      _isLoading = true;
    });

    _debounce = Timer(
      const Duration(
        milliseconds: 300,
      ),
      () {
        if (mounted) {
          _searchStocks(text);
        }
      },
    );
  }

  // ------------------------------------------
  // 실제 검색
  // ------------------------------------------

  Future<void> _searchStocks(
    String query,
  ) async {
    // 검색 실행 시 최근 검색어 저장
    await _saveRecentSearch(query);

    try {
      final json =
          await _searchApi.searchStocks(
        query,
      );

      final response =
          SearchResponseDto.fromJson(
        json,
      );

      final results =
          _convertSearchResults(
        response,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        '종목 검색 실패: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  // ------------------------------------------
  // 최근 검색어 클릭
  // ------------------------------------------

  void _selectRecentSearch(
    String query,
  ) {
    _searchController.text =
        query;

    _searchController.selection =
        TextSelection.fromPosition(
      TextPosition(
        offset:
            _searchController.text.length,
      ),
    );

    _focusNode.unfocus();
  }

  // ------------------------------------------
  // 검색 결과 변환
  // ------------------------------------------

  List<Map<String, dynamic>>
      _convertSearchResults(
    SearchResponseDto response,
  ) {
    return response.items
        .where(
          (item) => RegExp(
            r'^\d{6}$',
          ).hasMatch(item.code),
        )
        .map(
          (item) => {
            'name': item.name,
            'symbol': item.code,
            'exchange': item.typeName,
          },
        )
        .toList();
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _searchController.dispose();

    _focusNode.dispose();

    super.dispose();
  }

  // ------------------------------------------
  // 관심종목 토글
  // ------------------------------------------

  void _toggleFavorite(
    Map<String, dynamic> stock,
  ) {
    final provider =
        context.read<WatchlistProvider>();

    final name =
        stock['name'] as String;

    final symbol =
        stock['symbol'] as String;

    final exchange =
        stock['exchange'] as String;

    final isFavorite =
        provider.watchlist.any(
      (item) =>
          item.symbol == symbol,
    );

    if (isFavorite) {
      provider.removeFromWatchlist(
        symbol,
      );

      CustomToast.show(
        context,
        message: '관심이 해제되었습니다',
        icon: Icons.star_border,
        iconColor:
            context.colors.favoriteInactive,
      );
    } else {
      provider.addToWatchlist(
        WatchlistItem(
          symbol: symbol,
          name: name,
          exchange: exchange,
          currentPrice: 0,
          priceChange: 0,
          priceChangeRate: 0,
          isLoading: true,
        ),
      );

      CustomToast.show(
        context,
        message: '관심이 등록되었습니다',
        icon: Icons.star,
        iconColor:
            context.colors.favoriteActive,
      );
    }
  }

  // ------------------------------------------
  // 화면
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<WatchlistProvider>();

    return Scaffold(
      backgroundColor:
          context.colors.surfaceBase,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal:
                    context.dimens.space4,
                vertical:
                    context.dimens.space2,
              ),
              child:
                  _buildSearchBar(context),
            ),
            Expanded(
              child: _query.isEmpty
                  ? _buildInitialState(
                      context,
                    )
                  : _isLoading
                      ? _buildLoadingState(
                          context,
                        )
                      : _searchResults
                              .isNotEmpty
                          ? _buildSearchResults(
                              context,
                              _searchResults,
                              provider,
                            )
                          : _buildNoResultsState(
                              context,
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------
  // 검색창
  // ------------------------------------------

  Widget _buildSearchBar(
    BuildContext context,
  ) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color:
            context.colors.surfaceRaised,
        borderRadius:
            BorderRadius.circular(
          context.dimens.radiusMd,
        ),
      ),
      padding:
          EdgeInsets.symmetric(
        horizontal:
            context.dimens.space3,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color:
                context.colors.textSecondary,
            size: 20,
          ),

          SizedBox(
            width:
                context.dimens.space2,
          ),

          Expanded(
            child: TextField(
              controller:
                  _searchController,
              focusNode:
                  _focusNode,
              style: TextStyle(
                color:
                    context.colors.textPrimary,
                fontSize: 15,
              ),
              cursorColor:
                  context.colors.textPrimary,
              decoration:
                  InputDecoration(
                hintText:
                    '종목명 또는 종목코드',
                hintStyle:
                    TextStyle(
                  color:
                      context.colors.textSecondary,
                  fontSize: 15,
                ),
                border:
                    InputBorder.none,
                isDense: true,
                contentPadding:
                    EdgeInsets.zero,
              ),
            ),
          ),

          if (_isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color:
                    context.colors.textSecondary,
              ),
            )
          else if (
              _searchController.text
                  .isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
              },
              child: Icon(
                Icons.close,
                color:
                    context.colors.textSecondary,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // 초기 화면
  // ------------------------------------------

  Widget _buildInitialState(
    BuildContext context,
  ) {
    if (_recentSearches.isNotEmpty) {
      return _buildRecentSearches(
        context,
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 56,
            color:
                context.colors.textDisabled,
          ),

          SizedBox(
            height:
                context.dimens.space4,
          ),

          Text(
            '종목을 검색해 보세요',
            style: TextStyle(
              color:
                  context.colors.textPrimary,
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          SizedBox(
            height:
                context.dimens.space2,
          ),

          Text(
            '종목명 또는 종목코드 6자리로\n'
            '검색하실 수 있습니다.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color:
                  context.colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------
  // 최근 검색어
  // ------------------------------------------

  Widget _buildRecentSearches(
    BuildContext context,
  ) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal:
            context.dimens.space4,
      ),
      children: [
        SizedBox(
          height:
              context.dimens.space4,
        ),

        Row(
          children: [
            Text(
              '최근 검색어',
              style: TextStyle(
                color:
                    context.colors.textPrimary,
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const Spacer(),

            TextButton(
              onPressed:
                  _clearRecentSearches,
              child: Text(
                '전체 삭제',
                style: TextStyle(
                  color:
                      context.colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),

        SizedBox(
          height:
              context.dimens.space1,
        ),

        ..._recentSearches.map(
          (query) {
            return ListTile(
              contentPadding:
                  EdgeInsets.zero,

              leading: Icon(
                Icons.history,
                color:
                    context.colors.textTertiary,
                size: 20,
              ),

              title: Text(
                query,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      context.colors.textPrimary,
                  fontSize: 14,
                ),
              ),

              trailing:
                  GestureDetector(
                onTap: () =>
                    _removeRecentSearch(
                  query,
                ),
                child: Icon(
                  Icons.close,
                  color:
                      context.colors.textTertiary,
                  size: 18,
                ),
              ),

              onTap: () =>
                  _selectRecentSearch(
                query,
              ),
            );
          },
        ),
      ],
    );
  }

  // ------------------------------------------
  // 검색 로딩
  // ------------------------------------------

  Widget _buildLoadingState(
    BuildContext context,
  ) {
    return Center(
      child:
          CircularProgressIndicator(
        color:
            context.colors.textSecondary,
      ),
    );
  }

  // ------------------------------------------
  // 검색 결과
  // ------------------------------------------

  Widget _buildSearchResults(
    BuildContext context,
    List<Map<String, dynamic>>
        results,
    WatchlistProvider provider,
  ) {
    return ListView.separated(
      itemCount:
          results.length,
      separatorBuilder:
          (_, _) => Divider(
        color:
            context.colors.borderSubtle,
        height: 1,
      ),
      itemBuilder:
          (context, index) {
        final stock =
            results[index];

        final name =
            stock['name'] as String;

        final symbol =
            stock['symbol'] as String;

        final exchange =
            stock['exchange'] as String;

        final isFavorite =
            provider.watchlist.any(
          (item) =>
              item.symbol == symbol,
        );

        return ListTile(
          contentPadding:
              EdgeInsets.symmetric(
            horizontal:
                context.dimens.space4,
            vertical:
                context.dimens.space1,
          ),

          title:
              _buildHighlightedText(
            context,
            text: name,
            query: _query,
          ),

          subtitle: Text(
            '$symbol · $exchange',
            style: TextStyle(
              color:
                  context.colors.textSecondary,
              fontSize: 12,
            ),
          ),

          trailing:
              GestureDetector(
            onTap: () =>
                _toggleFavorite(
              stock,
            ),
            child: Icon(
              isFavorite
                  ? Icons.star
                  : Icons.star_border,
              color: isFavorite
                  ? context.colors.favoriteActive
                  : context.colors.favoriteInactive,
              size: 22,
            ),
          ),

          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ChangeNotifierProvider
                        .value(
                  value: context.read<
                      WatchlistProvider>(),
                  child:
                      StockDetailScreen(
                    stockName: name,
                    stockCode: symbol,
                    exchange:
                        exchange,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------
  // 검색 결과 없음
  // ------------------------------------------

  Widget _buildNoResultsState(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            EdgeInsets.symmetric(
          horizontal:
              context.dimens.space6,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Stack(
              alignment:
                  Alignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 56,
                  color:
                      context.colors.textDisabled,
                ),
                Positioned(
                  right: 25,
                  bottom: 24,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color:
                        context.colors.textDisabled,
                  ),
                ),
              ],
            ),

            SizedBox(
              height:
                  context.dimens.space4,
            ),

            Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                color:
                    context.colors.textPrimary,
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(
              height:
                  context.dimens.space2,
            ),

            Text(
              '\'$_query\'와\n'
              '일치하는 검색 결과를 찾지 못했습니다.',
              textAlign:
                  TextAlign.center,
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    context.colors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------
  // 검색어 하이라이트
  // ------------------------------------------

  Widget _buildHighlightedText(
    BuildContext context, {
    required String text,
    required String query,
  }) {
    if (query.isEmpty ||
        !text.contains(query)) {
      return Text(
        text,
        style: TextStyle(
          color:
              context.colors.textPrimary,
          fontWeight:
              FontWeight.bold,
          fontSize: 16,
        ),
      );
    }

    final startIndex =
        text.indexOf(query);

    final endIndex =
        startIndex + query.length;

    final beforeMatch =
        text.substring(
      0,
      startIndex,
    );

    final match =
        text.substring(
      startIndex,
      endIndex,
    );

    final afterMatch =
        text.substring(
      endIndex,
    );

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color:
              context.colors.textPrimary,
          fontWeight:
              FontWeight.bold,
          fontSize: 16,
          fontFamily:
              'NotoSansKR',
        ),
        children: [
          if (beforeMatch.isNotEmpty)
            TextSpan(
              text: beforeMatch,
            ),

          TextSpan(
            text: match,
            style: TextStyle(
              color:
                  context.colors.searchHighlight,
            ),
          ),

          if (afterMatch.isNotEmpty)
            TextSpan(
              text: afterMatch,
            ),
        ],
      ),
    );
  }
}