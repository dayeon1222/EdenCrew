import 'package:flutter/foundation.dart';

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
}

class WatchlistProvider extends ChangeNotifier {
  List<WatchlistItem> watchlist = [];

  SortType currentSort = SortType.price;

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

    bool isLoading = false;

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
  }

  void removeFromWatchlist(String symbol) {
    watchlist.removeWhere(
      (stock) => stock.symbol == symbol,
    );

    notifyListeners();
  }

  Future<void> loadWatchlist() async {
    // 실제 데이터 연결은 나중에 구현
    notifyListeners();
  }
}