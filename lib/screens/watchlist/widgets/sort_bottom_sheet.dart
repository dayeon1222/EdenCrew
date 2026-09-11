import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/theme.dart';
import '../../../providers/watchlist_provider.dart';

class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchlistProvider>();

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceRaised, 
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.dimens.radiusLg),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        context.dimens.space5,
        context.dimens.space6,
        context.dimens.space5,
        context.dimens.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '정렬',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.dimens.space4),
          _buildSortItem(context, provider, SortType.price, '현재가순'),
          _buildSortItem(context, provider, SortType.changeRate, '등락률순'),
          _buildSortItem(context, provider, SortType.name, '가나다순'),
        ],
      ),
    );
  }

  Widget _buildSortItem(
    BuildContext context,
    WatchlistProvider provider,
    SortType type,
    String label,
  ) {
    final isSelected = provider.currentSort == type;

    return InkWell(
      onTap: () {
        context.read<WatchlistProvider>().setSortType(type);
        Navigator.pop(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.dimens.space3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? context.colors.textPrimary
                    : context.colors.textSecondary,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: context.colors.textPrimary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}