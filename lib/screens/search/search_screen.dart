import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api/search_api.dart';
import '../../data/dto/search_dto.dart';
import '../../providers/watchlist_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/custom_toast.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController =
      TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SearchApi _searchApi = SearchApi();

  Timer? _debounce;

  bool _isLoading = false;

  String _query = '';

  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    final text = _searchController.text.trim();

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
      const Duration(milliseconds: 300),
      () {
        if (mounted) {
          _searchStocks(text);
        }
      },
    );
  }

  Future<void> _searchStocks(String query) async {
    try {
      final json = await _searchApi.searchStocks(query);

      final response = SearchResponseDto.fromJson(json);

      final results = _convertSearchResults(response);

      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('종목 검색 실패: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _convertSearchResults(
    SearchResponseDto response,
  ) {
    return response.items
        .where(
          (item) => RegExp(r'^\d{6}$').hasMatch(item.code),
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

  void _toggleFavorite(Map<String, dynamic> stock) {
    final provider = context.read<WatchlistProvider>();

    final name = stock['name'] as String;
    final symbol = stock['symbol'] as String;
    final exchange = stock['exchange'] as String;

    final isFavorite = provider.watchlist.any(
      (item) => item.symbol == symbol,
    );

    if (isFavorite) {
      provider.removeFromWatchlist(symbol);

      CustomToast.show(
        context,
        message: '관심이 해제되었습니다',
        icon: Icons.star_border,
        iconColor: context.colors.favoriteInactive,
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
        iconColor: context.colors.favoriteActive,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();

    return Scaffold(
      backgroundColor: context.colors.surfaceBase,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.dimens.space4,
                vertical: context.dimens.space2,
              ),
              child: _buildSearchBar(context),
            ),
            Expanded(
              child: _query.isEmpty
                  ? _buildInitialState(context)
                  : _isLoading
                      ? _buildLoadingState(context)
                      : _searchResults.isNotEmpty
                          ? _buildSearchResults(
                              context,
                              _searchResults,
                              provider,
                            )
                          : _buildNoResultsState(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(
          context.dimens.radiusMd,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.dimens.space3,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: context.colors.textSecondary,
            size: 20,
          ),
          SizedBox(width: context.dimens.space2),
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
          SizedBox(height: context.dimens.space2),
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

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: context.colors.textSecondary,
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    List<Map<String, dynamic>> results,
    WatchlistProvider provider,
  ) {
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => Divider(
        color: context.colors.borderSubtle,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final stock = results[index];

        final name = stock['name'] as String;
        final symbol = stock['symbol'] as String;
        final exchange = stock['exchange'] as String;

        final isFavorite = provider.watchlist.any(
          (item) => item.symbol == symbol,
        );

        return ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.dimens.space4,
            vertical: context.dimens.space1,
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
            onTap: () => _toggleFavorite(stock),
            child: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite
                  ? context.colors.favoriteActive
                  : context.colors.favoriteInactive,
              size: 22,
            ),
          ),
          onTap: () {
            // 종목 상세 화면 이동 처리
          },
        );
      },
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.dimens.space6,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                    Icons.search,
                    size: 56,
                    color: context.colors.textDisabled,
                ),
                Positioned(
                        right: 25,
                        bottom: 24,
                        child: Icon(
                            Icons.close,
                            size: 18,
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
            SizedBox(height: context.dimens.space2),
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

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontFamily: 'NotoSansKR',
        ),
        children: [
          if (beforeMatch.isNotEmpty)
            TextSpan(text: beforeMatch),
          TextSpan(
            text: match,
            style: TextStyle(
              color: context.colors.searchHighlight,
            ),
          ),
          if (afterMatch.isNotEmpty)
            TextSpan(text: afterMatch),
        ],
      ),
    );
  }
}