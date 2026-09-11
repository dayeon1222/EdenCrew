import 'package:flutter/foundation.dart';

import '../data/api/realtime_api.dart';
import '../data/dto/realtime_dto.dart';

enum SortType {
  price,
  changeRate,
  name,
}

extension SortTypeExtension on SortType {
  String get label {
    switch (this) {
      case SortType.price:
        return '현재가순';
      case SortType.changeRate:
        return '등락률순';
      case SortType.name:
        return '가나다순';
    }
  }
}

class WatchlistItem {
  final String symbol;
  final String name;
  final String exchange;
  final int currentPrice;
  final int priceChange;
  final double priceChangeRate;
  final bool isLoading;

  WatchlistItem({
    required this.symbol,
    required this.name,
    required this.exchange,
    required this.currentPrice,
    required this.priceChange,
    required this.priceChangeRate,
    this.isLoading = false,
  });

  WatchlistItem copyWith({
    int? currentPrice,
    int? priceChange,
    double? priceChangeRate,
    bool? isLoading,
  }) {
    return WatchlistItem(
      symbol: symbol,
      name: name,
      exchange: exchange,
      currentPrice: currentPrice ?? this.currentPrice,
      priceChange: priceChange ?? this.priceChange,
      priceChangeRate: priceChangeRate ?? this.priceChangeRate,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WatchlistProvider extends ChangeNotifier {
  final RealtimeApi _realtimeApi = RealtimeApi();

  List<WatchlistItem> watchlist = [];

  SortType currentSort = SortType.price;

  bool isLoading = false;

  List<WatchlistItem> get sortedWatchlist {
    final items = [...watchlist];

    switch (currentSort) {
      case SortType.price:
        items.sort(
          (a, b) => b.currentPrice.compareTo(a.currentPrice),
        );
        break;

      case SortType.changeRate:
        items.sort(
          (a, b) => b.priceChangeRate.compareTo(a.priceChangeRate),
        );
        break;

      case SortType.name:
        items.sort(
          (a, b) => a.name.compareTo(b.name),
        );
        break;
    }

    return items;
  }

  void setSortType(SortType type) {
    currentSort = type;
    notifyListeners();
  }

  void addToWatchlist(WatchlistItem item) {
    final alreadyExists = watchlist.any(
      (stock) => stock.symbol == item.symbol,
    );

    if (alreadyExists) {
      return;
    }

    watchlist.add(item);
    notifyListeners();

    _loadRealtimePrice(item.symbol);
  }

  void removeFromWatchlist(String symbol) {
    watchlist.removeWhere(
      (stock) => stock.symbol == symbol,
    );

    notifyListeners();
  }

  Future<void> _loadRealtimePrice(String symbol) async {
    try {
      final json = await _realtimeApi.fetchRealtime(
        symbols: [symbol],
      );

      final response = RealtimeResponseDto.fromJson(json);

      if (response.items.isEmpty) {
        return;
      }

      final realtimeItem = response.items.firstWhere(
        (item) => item.code == symbol,
        orElse: () => response.items.first,
      );

      final priceChange =
          realtimeItem.currentPrice - realtimeItem.previousClosePrice;

      final priceChangeRate =
          realtimeItem.previousClosePrice == 0
              ? 0.0
              : (priceChange / realtimeItem.previousClosePrice) * 100;

      final index = watchlist.indexWhere(
        (item) => item.symbol == symbol,
      );

      if (index == -1) {
        return;
      }

      watchlist[index] = watchlist[index].copyWith(
        currentPrice: realtimeItem.currentPrice,
        priceChange: priceChange,
        priceChangeRate: priceChangeRate,
        isLoading: false,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('실시간 시세 조회 실패: $symbol / $e');
    }
  }

  Future<void> loadWatchlist() async {
    if (watchlist.isEmpty) {
      return;
    }

    isLoading = true;

    watchlist = watchlist
        .map(
          (item) => item.copyWith(
            isLoading: true,
          ),
        )
        .toList();

    notifyListeners();

    try {
      final symbols = watchlist
          .map((item) => item.symbol)
          .toList();

      final json = await _realtimeApi.fetchRealtime(
        symbols: symbols,
      );

      final response = RealtimeResponseDto.fromJson(json);

      final realtimeMap = {
        for (final item in response.items)
          item.code: item,
      };

      watchlist = watchlist.map((item) {
        final realtimeItem = realtimeMap[item.symbol];

        if (realtimeItem == null) {
          return item.copyWith(
            isLoading: false,
          );
        }

        final priceChange =
            realtimeItem.currentPrice -
            realtimeItem.previousClosePrice;

        final priceChangeRate =
            realtimeItem.previousClosePrice == 0
                ? 0.0
                : (priceChange /
                        realtimeItem.previousClosePrice) *
                    100;

        return item.copyWith(
          currentPrice: realtimeItem.currentPrice,
          priceChange: priceChange,
          priceChangeRate: priceChangeRate,
          isLoading: false,
        );
      }).toList();
    } catch (e) {
      debugPrint('관심 종목 시세 조회 실패: $e');

      watchlist = watchlist
          .map(
            (item) => item.copyWith(
              isLoading: false,
            ),
          )
          .toList();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}