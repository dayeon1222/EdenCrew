import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/watchlist_provider.dart';
import 'widgets/sort_bottom_sheet.dart';
import '../../theme/theme.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();

    return Scaffold(
      backgroundColor: context.colors.surfaceBase, // 시맨틱 토큰 적용
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
          // 정렬 옵션 선택 버튼
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => const SortBottomSheet(),
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
                SizedBox(width: context.dimens.space1 ?? 2),
                Icon(
                  Icons.arrow_drop_down,
                  color: context.colors.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
          SizedBox(width: context.dimens.space3 ?? 12),
          // 새로고침 버튼
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: context.colors.textSecondary,
              size: 20,
            ),
            onPressed: () => provider.loadWatchlist(),
          ),
          SizedBox(width: context.dimens.space2 ?? 8),
        ],
      ),
      body: provider.watchlist.isEmpty && !provider.isLoading
          ? _buildEmptyState(context)
          : _buildStockList(context, provider),
    );
  }

  /// 빈 상태 (Empty State)
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
          SizedBox(height: context.dimens.space2 ?? 8),
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

  /// 종목 리스트
  Widget _buildStockList(BuildContext context, WatchlistProvider provider) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: context.dimens.space2 ?? 8),
      itemCount: provider.sortedWatchlist.length,
      separatorBuilder: (_, __) => Divider(
      color: context.colors.borderSubtle,
      height: 1,
    ),
      itemBuilder: (context, index) {
        final item = provider.sortedWatchlist[index];

        return ListTile(
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
            // 상세 화면으로 이동
          },
        );
      },
    );
  }

  /// 우측 가격 및 등락 표시 (상승/하락 시맨틱 컬러 적용)
  Widget _buildPriceInfo(BuildContext context, dynamic item) {
    final isUp = item.priceChange > 0;
    final isDown = item.priceChange < 0;

    // 시맨틱 토큰 적용 (상승: priceUp / 하락: priceDown / 보합: textSecondary)
    final priceColor = isUp
        ? context.colors.priceUpText
        : isDown
            ? context.colors.priceDownText
            : context.colors.textSecondary;

    final priceStr = item.currentPrice.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    final changeText =
        '${isUp ? '+' : ''}${item.priceChange} (${isUp ? '+' : ''}${item.priceChangeRate.toStringAsFixed(2)}%)';

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
        SizedBox(height: context.dimens.space1 ?? 2),
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
    final skeletonColor =
        context.colors.surfaceRaised;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 60,
          height: 16,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(context.dimens.radiusSm ?? 4),
          ),
        ),
        SizedBox(height: context.dimens.space1 ?? 6),
        Container(
          width: 40,
          height: 12,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(context.dimens.radiusSm ?? 4),
          ),
        ),
      ],
    );
  }
}