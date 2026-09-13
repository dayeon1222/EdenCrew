import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api/daily_price_api.dart';
import '../../data/api/realtime_api.dart';
import '../../data/dto/realtime_dto.dart';
import '../../data/parser/daily_price_parser.dart';
import '../../providers/watchlist_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/custom_toast.dart';
import 'widgets/stock_candle_chart.dart';

class StockDetailScreen extends StatefulWidget {
  final String stockName;
  final String stockCode;
  final String exchange;

  const StockDetailScreen({
    super.key,
    this.stockName = '삼성전자',
    this.stockCode = '005930',
    this.exchange = '코스피',
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final DailyPriceApi _dailyPriceApi = DailyPriceApi();
  final RealtimeApi _realtimeApi = RealtimeApi();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;

  String _selectedPeriod = '1개월';

  int _currentPage = 1;
  int _lastPage = 1;

  int _currentPrice = 0;
  int _priceChange = 0;
  double _changeRate = 0;

  int _openPrice = 0;
  int _highPrice = 0;
  int _lowPrice = 0;
  int _volume = 0;
  int _marketCap = 0;

  List<CandleData> _candles = [];
  List<Map<String, dynamic>> _dailyPrices = [];

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    _loadPeriodData(_selectedPeriod);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  int _getRequiredCount(String period) {
    switch (period) {
      case '3개월':
        return 70;
      case '6개월':
        return 130;
      case '1년':
        return 260;
      case '1개월':
      default:
        return 25;
    }
  }

  Future<void> _loadPeriodData(String period) async {
    setState(() {
      _selectedPeriod = period;
      _isLoading = true;
      _currentPage = 1;
      _lastPage = 1;
      _dailyPrices = [];
      _candles = [];
    });

    try {
      final requiredCount = _getRequiredCount(period);

      final allPrices = <dynamic>[];

      var page = 1;

      while (allPrices.length < requiredCount) {
        final html = await _dailyPriceApi.fetchDailyPriceHtml(
          code: widget.stockCode,
          page: page,
        );

        final response = parseDailyPrices(html);

        if (response.prices.isEmpty) {
          break;
        }

        allPrices.addAll(response.prices);

        _lastPage = response.lastPage;

        if (page >= response.lastPage) {
          break;
        }

        page++;
      }

      final prices = allPrices.take(requiredCount).toList();

      if (prices.isEmpty) {
        throw Exception(
          '일별 시세 데이터를 불러오지 못했습니다.',
        );
      }

      final realtimeJson = await _realtimeApi.fetchRealtime(
        symbols: [widget.stockCode],
      );

      final realtimeResponse =
          RealtimeResponseDto.fromJson(realtimeJson);

      if (realtimeResponse.items.isEmpty) {
        throw Exception(
          '실시간 주가 데이터를 불러오지 못했습니다.',
        );
      }

      final realtime = realtimeResponse.items.first;

      final nv = realtime.currentPrice;
      final pcv = realtime.previousClosePrice;

      final change = nv - pcv;

      final changeRate = pcv == 0
          ? 0.0
          : (change / pcv) * 100;

      final marketCap =
          nv * realtime.listedStockCount;

      final candles = prices.reversed.map((price) {
        return CandleData(
          date: _parseDate(price.localDate),
          open: price.openPrice.toDouble(),
          high: price.highPrice.toDouble(),
          low: price.lowPrice.toDouble(),
          close: price.closePrice.toDouble(),
          volume:
              price.accumulatedTradingVolume.toDouble(),
        );
      }).toList();

      final dailyPrices = prices.map((price) {
        final index = prices.indexOf(price);

        final previous = index + 1 < prices.length
            ? prices[index + 1].closePrice
            : null;

        final dailyChange =
            previous == null
                ? 0
                : price.closePrice - previous;

        return {
          'date': _formatDate(price.localDate),
          'close': price.closePrice,
          'change': dailyChange,
          'volume': price.accumulatedTradingVolume,
        };
      }).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentPrice = nv;
        _priceChange = change;
        _changeRate = changeRate;

        _openPrice = realtime.openPrice;
        _highPrice = realtime.highPrice;
        _lowPrice = realtime.lowPrice;
        _volume = realtime.accumulatedVolume;
        _marketCap = marketCap;

        _candles = candles;
        _dailyPrices = dailyPrices;

        _currentPage = page;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      CustomToast.show(
        context,
        message: '주가 데이터를 불러오지 못했습니다.',
        icon: Icons.error_outline,
        iconColor: context.colors.feedbackWarning,
      );
    }
  }

  Future<void> _loadMoreDailyPrices() async {
    if (_isLoadingMore ||
        _currentPage >= _lastPage) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;

      final html =
          await _dailyPriceApi.fetchDailyPriceHtml(
        code: widget.stockCode,
        page: nextPage,
      );

      final response = parseDailyPrices(html);

      if (!mounted) {
        return;
      }

      final newItems = response.prices.map((price) {
        return {
          'date': _formatDate(price.localDate),
          'close': price.closePrice,
          'change': 0,
          'volume': price.accumulatedTradingVolume,
        };
      }).toList();

      final existingDates = _dailyPrices
          .map((item) => item['date'] as String)
          .toSet();

      final filteredItems =
          newItems.where((item) {
        return !existingDates.contains(
          item['date'],
        );
      }).toList();

      // 새 페이지 내부의 등락 계산
      for (var i = 0;
          i < filteredItems.length - 1;
          i++) {
        final current =
            filteredItems[i]['close'] as int;

        final previous =
            filteredItems[i + 1]['close'] as int;

        filteredItems[i]['change'] =
            current - previous;
      }

      // 기존 마지막 데이터와 새 페이지 첫 데이터 연결
      if (_dailyPrices.isNotEmpty &&
          filteredItems.isNotEmpty) {
        final previousClose =
            filteredItems[0]['close'] as int;

        final lastIndex =
            _dailyPrices.length - 1;

        final lastClose =
            _dailyPrices[lastIndex]['close'] as int;

        _dailyPrices[lastIndex]['change'] =
            lastClose - previousClose;
      }

      setState(() {
        _dailyPrices.addAll(filteredItems);
        _currentPage = nextPage;
        _lastPage = response.lastPage;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent -
                200 &&
        !_isLoadingMore) {
      _loadMoreDailyPrices();
    }
  }

  DateTime _parseDate(String value) {
    final year = int.parse(
      value.substring(0, 4),
    );

    final month = int.parse(
      value.substring(4, 6),
    );

    final day = int.parse(
      value.substring(6, 8),
    );

    return DateTime(year, month, day);
  }

  String _formatDate(String value) {
    if (value.length != 8) {
      return value;
    }

    return '${value.substring(4, 6)}.'
        '${value.substring(6, 8)}';
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(
            r'(\d{1,3})(?=(\d{3})+(?!\d))',
          ),
          (match) => '${match[1]},',
        );
  }

  String _formatVolume(int volume) {
    if (volume >= 100000000) {
      return '${(volume / 100000000).toStringAsFixed(1)}억';
    }

    if (volume >= 10000) {
      return '${(volume / 10000).toStringAsFixed(1)}만';
    }

    return _formatNumber(volume);
  }

  String _formatMarketCap(int marketCap) {
    if (marketCap >= 100000000000000) {
      return '${(marketCap / 100000000000000).toStringAsFixed(1)}백조';
    }

    if (marketCap >= 1000000000000) {
      return '${(marketCap / 1000000000000).toStringAsFixed(1)}조';
    }

    if (marketCap >= 100000000) {
      return '${(marketCap / 100000000).toStringAsFixed(1)}억';
    }

    return _formatNumber(marketCap);
  }

  /// 관심종목 추가/삭제
  void _toggleFavorite(bool isFavorite) {
    final provider =
        context.read<WatchlistProvider>();

    if (isFavorite) {
      provider.removeFromWatchlist(
        widget.stockCode,
      );

      CustomToast.show(
        context,
        message:
            '${widget.stockName}이(가) 관심종목에서 삭제되었습니다.',
        icon: Icons.star_border,
        iconColor:
            context.colors.favoriteInactive,
      );
    } else {
      provider.addToWatchlist(
        WatchlistItem(
          symbol: widget.stockCode,
          name: widget.stockName,
          exchange: widget.exchange,
          currentPrice: _currentPrice,
          priceChange: _priceChange,
          priceChangeRate: _changeRate,
          isLoading: _isLoading,
        ),
      );

      CustomToast.show(
        context,
        message:
            '${widget.stockName}이(가) 관심종목에 추가되었습니다.',
        icon: Icons.star,
        iconColor:
            context.colors.favoriteActive,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<WatchlistProvider>();

    final isFavorite = provider.watchlist.any(
      (item) => item.symbol == widget.stockCode,
    );

    final isUp = _priceChange > 0;
    final isDown = _priceChange < 0;

    final priceColor = isUp
        ? context.colors.priceUpText
        : isDown
            ? context.colors.priceDownText
            : context.colors.priceFlatText;

    final arrowIcon = isUp
        ? '▲'
        : (isDown ? '▼' : '');

    return Scaffold(
      backgroundColor: context.colors.surfaceBase,

      appBar: AppBar(
        backgroundColor:
            context.colors.surfaceBase,
        elevation: 0,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: context.colors.textPrimary,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.stockName,
              style: TextStyle(
                color:
                    context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.stockCode} · ${widget.exchange}',
              style: TextStyle(
                color:
                    context.colors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: Icon(
              isFavorite
                  ? Icons.star
                  : Icons.star_border,
              color: isFavorite
                  ? context.colors.favoriteActive
                  : context.colors.favoriteInactive,
            ),
            onPressed: () {
              _toggleFavorite(isFavorite);
            },
          ),
        ],
      ),

      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color:
                    context.colors.accentDefault,
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      context.dimens.space4,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.baseline,
                      textBaseline:
                          TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatNumber(
                            _currentPrice,
                          ),
                          style: TextStyle(
                            color:
                                context.colors.textPrimary,
                            fontSize: 32,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Text(
                          '$arrowIcon '
                          '${_formatNumber(_priceChange.abs())} '
                          '(${_changeRate.toStringAsFixed(2)}%)',
                          style: TextStyle(
                            color: priceColor,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildPeriodTabs(context),

                    const SizedBox(height: 16),

                    AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: 300,
                      ),
                      child: StockCandleChart(
                        key: ValueKey(
                          _selectedPeriod,
                        ),
                        candles: _candles,
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildSummaryCards(context),

                    const SizedBox(height: 28),

                    Text(
                      '일별 시세',
                      style: TextStyle(
                        color:
                            context.colors.textPrimary,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildDailyPriceTable(context),

                    if (_isLoadingMore)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        child: Center(
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context
                                .colors
                                .textSecondary,
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodTabs(
    BuildContext context,
  ) {
    final periods = [
      '1개월',
      '3개월',
      '6개월',
      '1년',
    ];

    return Row(
      children: periods.map((period) {
        final isSelected =
            period == _selectedPeriod;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              _loadPeriodData(period);
            },
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 200,
              ),
              margin:
                  const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              padding:
                  const EdgeInsets.symmetric(
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colors.accentBg
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected
                        ? context
                            .colors
                            .accentDefault
                        : context
                            .colors
                            .textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
  ) {
    return Column(
      children: [
        Row(
          children: [
            _buildInfoTile(
              '시가',
              _formatNumber(_openPrice),
            ),
            const SizedBox(width: 8),
            _buildInfoTile(
              '고가',
              _formatNumber(_highPrice),
            ),
            const SizedBox(width: 8),
            _buildInfoTile(
              '저가',
              _formatNumber(_lowPrice),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            _buildInfoTile(
              '거래량',
              _formatVolume(_volume),
            ),
            const SizedBox(width: 8),
            _buildInfoTile(
              '시가총액',
              _formatMarketCap(_marketCap),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
  ) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color:
              context.colors.surfaceRaised,
          borderRadius:
              BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color:
                    context.colors.textSecondary,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              value,
              style: TextStyle(
                color:
                    context.colors.textPrimary,
                fontSize: 15,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyPriceTable(
    BuildContext context,
  ) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 8,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '날짜',
                  style: TextStyle(
                    color: context
                        .colors
                        .textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),

              Expanded(
                flex: 3,
                child: Text(
                  '종가',
                  textAlign:
                      TextAlign.right,
                  style: TextStyle(
                    color: context
                        .colors
                        .textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),

              Expanded(
                flex: 3,
                child: Text(
                  '등락',
                  textAlign:
                      TextAlign.right,
                  style: TextStyle(
                    color: context
                        .colors
                        .textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),

              Expanded(
                flex: 4,
                child: Text(
                  '거래량',
                  textAlign:
                      TextAlign.right,
                  style: TextStyle(
                    color: context
                        .colors
                        .textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        ..._dailyPrices.map((item) {
          final change =
              item['change'] as int;

          final isUp = change > 0;
          final isDown = change < 0;

          final color = isUp
              ? context.colors.priceUpText
              : isDown
                  ? context.colors.priceDownText
                  : context.colors.priceFlatText;

          final sign = isUp ? '+' : '';

          return Container(
            padding:
                const EdgeInsets.symmetric(
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      context.colors.borderSubtle,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    item['date'] as String,
                    style: TextStyle(
                      color: context
                          .colors
                          .textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),

                Expanded(
                  flex: 3,
                  child: Text(
                    _formatNumber(
                      item['close'] as int,
                    ),
                    textAlign:
                        TextAlign.right,
                    style: TextStyle(
                      color: context
                          .colors
                          .textPrimary,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),

                Expanded(
                  flex: 3,
                  child: Text(
                    change == 0
                        ? '0'
                        : '$sign${_formatNumber(change)}',
                    textAlign:
                        TextAlign.right,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),

                Expanded(
                  flex: 4,
                  child: Text(
                    _formatNumber(
                      item['volume'] as int,
                    ),
                    textAlign:
                        TextAlign.right,
                    style: TextStyle(
                      color: context
                          .colors
                          .textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}