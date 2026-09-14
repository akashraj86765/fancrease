import 'package:flutter/material.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'services_screen.dart';
import 'orders_screen.dart';
import 'wallet_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = [
    DashboardScreen(),
    ServicesScreen(),
    OrdersScreen(),
    WalletScreen(),
  ];

  static const _destinations = [
    _NavItem(label: 'Dashboard', icon: Icons.grid_view_rounded),
    _NavItem(label: 'Services', icon: Icons.rocket_launch_rounded),
    _NavItem(label: 'Orders', icon: Icons.receipt_long_rounded),
    _NavItem(label: 'Wallet', icon: Icons.account_balance_wallet_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _Sidebar(
              index: _index,
              destinations: _destinations,
              onSelect: (i) => setState(() => _index = i),
            ),
            Expanded(child: _pages[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_index],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: _destinations
              .map((d) => NavigationDestination(
                    icon: Icon(d.icon, color: AppColors.textSecondary),
                    selectedIcon: Icon(d.icon, color: AppColors.primary),
                    label: d.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem({required this.label, required this.icon});
}

class _Sidebar extends StatelessWidget {
  final int index;
  final List<_NavItem> destinations;
  final ValueChanged<int> onSelect;

  const _Sidebar({
    required this.index,
    required this.destinations,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Fancrease',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          ...destinations.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            final selected = i == index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Material(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelect(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          d.icon,
                          size: 22,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          d.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}