import 'package:flutter/material.dart';
import 'watchlist/watchlist_screen.dart';
import '../theme/theme.dart';
import 'search/search_screen.dart'; // 3일 차에 만들 검색 화면

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

final List<Widget> _screens = const [
  WatchlistScreen(),
  SearchScreen(),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceBase,
          border: Border(
            top: BorderSide(
             color: context.colors.borderSubtle,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: context.colors.surfaceBase,
          // 선택된 탭: 흰색 (textPrimary)
          selectedItemColor: context.colors.textPrimary,
          // 비선택 탭: 회색 (textSecondary)
          unselectedItemColor: context.colors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.normal,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.star, size: 22),
              ),
              label: '관심',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.search, size: 22),
              ),
              label: '검색',
            ),
          ],
        ),
      ),
    );
  }
}