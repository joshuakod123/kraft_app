import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/department_enum.dart';
import '../../core/state/global_providers.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/streaming/mini_player.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/archive')) currentIndex = 1;
    if (location.startsWith('/stream')) currentIndex = 2;

    final dept = ref.watch(currentDeptProvider);

    return Scaffold(
      body: Stack(
        children: [child, const MiniPlayer()],
      ),
      appBar: AppBar(
        title: Text('KRAFT', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          backgroundColor: kAppBackgroundColor,
          indicatorColor: dept.color.withValues(alpha: 0.2),
          onDestinationSelected: (index) {
            switch (index) {
              case 0: context.go('/home'); break;
              case 1: context.go('/archive'); break;
              case 2: context.go('/stream'); break;
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.folder_open), selectedIcon: Icon(Icons.folder), label: 'Archive'),
            NavigationDestination(icon: Icon(Icons.headphones_outlined), selectedIcon: Icon(Icons.headphones), label: 'Stream'),
          ],
        ),
      ),
    );
  }
}