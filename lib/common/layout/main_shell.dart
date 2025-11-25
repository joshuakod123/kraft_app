import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../features/auth/auth_provider.dart';
import '../../theme/app_theme.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/archive')) currentIndex = 1;
    if (location.startsWith('/stream')) currentIndex = 2;

    final dept = ref.watch(currentDeptProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'KRAFT',
          style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Team Select',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // [수정] withOpacity로 변경
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          backgroundColor: kAppBackgroundColor,
          // [수정] withOpacity로 변경
          indicatorColor: dept.color.withOpacity(0.2),
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/home');
                break;
              case 1:
                context.go('/archive');
                break;
              case 2:
                context.go('/stream');
                break;
            }
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.folder_open),
              selectedIcon: Icon(Icons.folder, color: dept.color),
              label: 'Archive',
            ),
            NavigationDestination(
              icon: const Icon(Icons.headphones_outlined),
              selectedIcon: Icon(Icons.headphones, color: dept.color),
              label: 'Stream',
            ),
          ],
        ),
      ),
    );
  }
}