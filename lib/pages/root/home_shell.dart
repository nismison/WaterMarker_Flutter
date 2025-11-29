import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:watermarker_v2/pages/business/index.dart';
import 'package:watermarker_v2/widgets/sliding_bottom_nav_bar.dart';

import '../business/orders.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final List<Widget> _pages = const [
    IndexPage(),
    OrdersPage(),
    Placeholder()
  ];

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      footer: SlidingBottomNavBar(
        currentIndex: index,
        onChange: (value) => setState(() => index = value),
        items: const [
          SlidingNavBarItem(
            icon: FIcons.filePenLine,
            label: '生成水印',
          ),
          SlidingNavBarItem(
            icon: FIcons.notepadText,
            label: '百川工单',
          ),
          SlidingNavBarItem(
            icon: FIcons.settings2,
            label: '设置',
          ),
        ],
      ),
      child: _pages[index],
    );
  }
}
