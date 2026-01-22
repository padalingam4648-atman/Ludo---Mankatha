
import 'package:flutter/material.dart';
import '../logic/ludo_logic.dart';

class MankathaDesignSystem {
  final DashboardTheme theme;
  MankathaDesignSystem(this.theme);

  Color get background {
    switch (theme) {
      case DashboardTheme.light: return const Color(0xFFF1F5F9);
      case DashboardTheme.dark: return const Color(0xFF0F172A);
      case DashboardTheme.elite: return const Color(0xFF020617);
    }
  }

  Color get cardBg {
    switch (theme) {
      case DashboardTheme.light: return Colors.white;
      case DashboardTheme.dark: return const Color(0xFF1E293B);
      case DashboardTheme.elite: return const Color(0xFF0F172A);
    }
  }

  Color get textPrimary {
    switch (theme) {
      case DashboardTheme.light: return const Color(0xFF0F172A);
      default: return Colors.white;
    }
  }

  Color get textSecondary {
    switch (theme) {
      case DashboardTheme.light: return const Color(0xFF64748B);
      default: return const Color(0xFF94A3B8);
    }
  }

  Color get accent {
    switch (theme) {
      case DashboardTheme.light: return const Color(0xFF3B82F6);
      case DashboardTheme.dark: return const Color(0xFF8B5CF6);
      case DashboardTheme.elite: return const Color(0xFFFACC15);
    }
  }

  List<Color> get primaryGradient {
    switch (theme) {
      case DashboardTheme.light: return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      case DashboardTheme.dark: return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      case DashboardTheme.elite: return [const Color(0xFFFACC15), const Color(0xFFEAB308)];
    }
  }

  Color get glassBorder {
    return textPrimary.withOpacity(0.1);
  }

  BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBg.withOpacity(theme == DashboardTheme.light ? 1.0 : 0.7),
    borderRadius: BorderRadius.circular(32),
    border: Border.all(color: glassBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        offset: const Offset(0, 10),
      )
    ],
  );
}
