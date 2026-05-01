import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'map_screen.dart';

// ── Placeholder screen for tabs not yet implemented ──────────────────────────
class _ComingSoonScreen extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ComingSoonScreen({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: TextStyle(
              color: const Color(0xFFFFFFFF).withAlpha(153),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Main Scaffold ─────────────────────────────────────────────────────────────
class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key});

  bool _needsGradient(int index) => index >= 2;

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final index = provider.selectedNavIndex;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: _needsGradient(index)
                ? AtmosTheme.backgroundDecoration
                : const BoxDecoration(color: Colors.transparent),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top Bar — shown on all tabs except Map (map has its own overlay)
                  if (index != 1) _TopBar(provider: provider),

                  // Page content
                  Expanded(
                    child: IndexedStack(
                      index: index,
                      children: const [
                        HomeScreen(), // 0 – ✅ Home
                        MapScreen(), // 1 – ✅ Map
                        _ComingSoonScreen(
                          // 2 – 🔜 Alerts
                          label: 'Alerts',
                          icon: Icons.notifications_rounded,
                        ),
                        _ComingSoonScreen(
                          // 3 – 🔜 Reminders
                          label: 'Reminders',
                          icon: Icons.alarm_rounded,
                        ),
                        _ComingSoonScreen(
                          // 4 – 🔜 Explore
                          label: 'Explore',
                          icon: Icons.explore_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _AtmosBottomNav(
            selectedIndex: index,
            onTap: provider.setNavIndex,
          ),
        );
      },
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final WeatherProvider provider;
  const _TopBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        final searchField = GestureDetector(
          onTap: () => provider.setNavIndex(1),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF).withAlpha(64),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFFFFF).withAlpha(90)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.currentWeather?.cityName ?? 'Search location...',
                    style: TextStyle(
                      color: const Color(0xFFFFFFFF).withAlpha(220),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
        final refreshButton = GestureDetector(
          onTap: provider.status == WeatherStatus.loading
              ? null
              : provider.refresh,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF).withAlpha(51),
              borderRadius: BorderRadius.circular(10),
            ),
            child: provider.status == WeatherStatus.loading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 20),
          ),
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'ATMOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const Spacer(),
                        refreshButton,
                      ],
                    ),
                    const SizedBox(height: 10),
                    searchField,
                  ],
                )
              : Row(
                  children: [
                    const Text(
                      'ATMOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: searchField),
                    const SizedBox(width: 8),
                    refreshButton,
                  ],
                ),
        );
      },
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _AtmosBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _AtmosBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.map_rounded, label: 'Map'),
      _NavItem(icon: Icons.notifications_rounded, label: 'Alerts'),
      _NavItem(icon: Icons.alarm_rounded, label: 'Reminders'),
      _NavItem(icon: Icons.explore_rounded, label: 'Explore'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AtmosTheme.primaryBlue.withAlpha(31),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final isSelected = selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AtmosTheme.lightBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          items[i].icon,
                          color: isSelected
                              ? AtmosTheme.primaryBlue
                              : AtmosTheme.textSecondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          color: isSelected
                              ? AtmosTheme.primaryBlue
                              : AtmosTheme.textSecondary,
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
