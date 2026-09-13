import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/watchlist_provider.dart';
import 'widgets/sort_bottom_sheet.dart';
import '../../theme/theme.dart';
import '../detail/stock_detail_screen.dart';
import '../../widgets/custom_toast.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();

    return Scaffold(
      backgroundColor: context.colors.surfaceBase,
      appBar: AppBar(
        backgroundColor: context.colors.surfaceBase,
        elevation: 0,
        title: Text(
          '관심',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // 정렬 옵션
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) {
                  return ChangeNotifierProvider.value(
                    value: context.read<WatchlistProvider>(),
                    child: const SortBottomSheet(),
                  );
                },
              );
            },
            child: Row(
              children: [
                Text(
                  provider.currentSort.label,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: context.dimens.space1),
                Icon(
                  Icons.arrow_drop_down,
                  color: context.colors.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),

          SizedBox(width: context.dimens.space3),

          // 새로고침
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: context.colors.textSecondary,
              size: 20,
            ),
            onPressed: () {
              provider.loadWatchlist();
            },
          ),

          SizedBox(width: context.dimens.space2),
        ],
      ),

      body: provider.watchlist.isEmpty && !provider.isLoading
          ? _buildEmptyState(context)
          : RefreshIndicator(
              color: context.colors.accentDefault,
              onRefresh: provider.loadWatchlist,
              child: _buildStockList(context, provider),
            ),
    );
  }

  /// 빈 상태
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline,
            size: 60,
            color: context.colors.textDisabled,
          ),

          SizedBox(height: context.dimens.space4),

          Text(
            '관심 종목이 없습니다',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: context.dimens.space2),

          Text(
            '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
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

  /// 관심 종목 리스트
  Widget _buildStockList(
    BuildContext context,
    WatchlistProvider provider,
  ) {
    final items = provider.sortedWatchlist;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        vertical: context.dimens.space2,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) {
        return Divider(
          color: context.colors.borderSubtle,
          height: 1,
        );
      },
      itemBuilder: (context, index) {
        final item = items[index];

        return Dismissible(
          key: ValueKey(item.symbol),

          direction: DismissDirection.endToStart,

          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(
              right: context.dimens.space4,
            ),
            color: context.colors.priceDownBg,
            child: Icon(
              Icons.delete_outline,
              color: context.colors.priceDownText,
            ),
          ),

          onDismissed: (_) {
            provider.removeFromWatchlist(item.symbol);

            CustomToast.show(
              context,
              message: '관심이 해제되었습니다',
              icon: Icons.star_border,
              iconColor: context.colors.favoriteInactive,
            );
          },

          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.dimens.space4,
              vertical: context.dimens.space1,
            ),

            title: Text(
              item.name,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            subtitle: Text(
              '${item.symbol} · ${item.exchange}',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),

            trailing: item.isLoading
                ? _buildSkeletonPrice(context)
                : _buildPriceInfo(context, item),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<WatchlistProvider>(),
                    child: StockDetailScreen(
                      stockName: item.name,
                      stockCode: item.symbol,
                      exchange: item.exchange,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 우측 가격 및 등락 표시
  Widget _buildPriceInfo(
    BuildContext context,
    WatchlistItem item,
  ) {
    final isUp = item.priceChange > 0;
    final isDown = item.priceChange < 0;

    final priceColor = isUp
        ? context.colors.priceUpText
        : isDown
            ? context.colors.priceDownText
            : context.colors.priceFlatText;

    final priceStr = item.currentPrice.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );

    final changeSign = isUp ? '+' : '';

    final changeText =
        '$changeSign${item.priceChange} '
        '($changeSign${item.priceChangeRate.toStringAsFixed(2)}%)';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          priceStr,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        SizedBox(height: context.dimens.space1),

        Text(
          changeText,
          style: TextStyle(
            color: priceColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 스켈레톤 UI
  Widget _buildSkeletonPrice(BuildContext context) {
    final skeletonColor = context.colors.feedbackSkeleton;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 60,
          height: 16,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(
              context.dimens.radiusSm,
            ),
          ),
        ),

        SizedBox(height: context.dimens.space1),

        Container(
          width: 40,
          height: 12,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(
              context.dimens.radiusSm,
            ),
          ),
        ),
      ],
    );
  }
}