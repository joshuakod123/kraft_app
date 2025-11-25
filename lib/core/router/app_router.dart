import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../constants/department_enum.dart'; // BottomNavi에서 색상 쓰기 위함

// 간단한 Shell (Bottom Navigation) 구현을 위해 여기서 바로 정의
// 실제로는 별도 파일로 분리하는 것이 좋습니다.
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
      // context.go('/archive'); // 추후 구현
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
        selectedItemColor: Colors.white, // 선택된 아이콘 (임시)
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Archive'),
          BottomNavigationBarItem(icon: Icon(Icons.headphones), label: 'Stream'),
        ],
      ),
    );
  }
}

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return MainShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    ),
  ],
);