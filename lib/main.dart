import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'board/board_screen.dart';
import 'island/island_screen.dart';

void main() {
  runApp(const ProviderScope(child: AdaBlastApp()));
}

class AdaBlastApp extends StatelessWidget {
  const AdaBlastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ada Blast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0E2033),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8B5E),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeShell(),
    );
  }
}

/// Board ve Island ekranları arasında yatay kaydırma ile geçiş sağlayan
/// ana kabuk (bkz. docs/GDD.md, Bölüm 8.2 - Navigasyon).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) => setState(() => _page = page),
        children: const [BoardScreen(), IslandScreen()],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavDot(label: '🧩 Tahta', selected: _page == 0, onTap: () => _goTo(0)),
              const SizedBox(width: 24),
              _NavDot(label: '🏝️ Ada', selected: _page == 1, onTap: () => _goTo(1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavDot extends StatelessWidget {
  const _NavDot({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: selected ? 1 : 0.4,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFEFE6D3),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
