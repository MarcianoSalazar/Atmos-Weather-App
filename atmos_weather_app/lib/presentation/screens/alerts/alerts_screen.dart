// lib/presentation/screens/alerts/alerts_screen.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.skyGradient),
        child: const SafeArea(
          child: _ComingSoon(
            title: 'ALERTS',
            subtitle: 'Coming soon',
            icon: Icons.notifications_rounded,
          ),
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ComingSoon({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.white40, size: 72),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 14,
              color: AppColors.white60,
            ),
          ),
        ],
      ),
    );
  }
}
