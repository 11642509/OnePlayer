import 'package:flutter/material.dart';
import '../app/data_source.dart';
import 'vlc_tab.dart';

class VlcPlayerPage extends StatelessWidget {
  final VideoPlayConfig playConfig;
  final String title;

  const VlcPlayerPage({
    super.key,
    required this.playConfig,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 保持背景色为黑色
      body: VlcTab( // 直接将VlcTab作为body
        playConfig: playConfig,
        title: title,
      ),
    );
  }
} 