import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'board/board_screen.dart';

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
      home: const BoardScreen(),
    );
  }
}
