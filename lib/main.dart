import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'board/board_screen.dart';
import 'collection/collection_panel.dart';
import 'island/island_screen.dart';
import 'quests/logic/daily_quest_controller.dart';
import 'quests/quest_panel.dart';

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
/// ana kabuk (bkz. docs/GDD.md, Bölüm 8.2 - Navigasyon). Görevler ve
/// Koleksiyon, her iki ekranda da erişilebilen üst köşe ikonlarıyla modal
/// olarak açılır.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dailyQuestControllerProvider.notifier).checkNewDay();
    });
  }

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
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _page = page),
            children: const [BoardScreen(), IslandScreen()],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _TopIconButton(
                    icon: '📋',
                    onTap: () => showQuestPanel(context),
                  ),
                  const SizedBox(width: 8),
                  _TopIconButton(
                    icon: '📖',
                    onTap: () => showCollectionPanel(context),
                  ),
                ],
              ),
            ),
          ),
        ],
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

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF16304A),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(icon, style: const TextStyle(fontSize: 18)),
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
