import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/department_enum.dart';

// 하단 네비게이션 바(BottomNavigationBar)를 포함하는 껍데기 위젯
class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onItemTapped(int index, BuildContext context) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/curriculum');
        break;
      case 2:
      // context.go('/stream'); // 추후 구현
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => _onItemTapped(idx, context),
        backgroundColor: kAppBackgroundColor,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Curriculum'),
          BottomNavigationBarItem(icon: Icon(Icons.headphones), label: 'Stream'),
        ],
      ),
    );
  }
}