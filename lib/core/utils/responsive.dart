// lib/core/utils/responsive.dart
//
// Central responsive layout helper for Lugmatic.
// All breakpoint decisions flow through this file so changes are easy.

import 'package:flutter/material.dart';

/// Screen-width breakpoints (logical pixels).
const double _kTabletBreakpoint = 600;
const double _kDesktopBreakpoint = 1024;

/// Max width for page content so it never stretches across the full width
/// of a large tablet or desktop screen.
const double kContentMaxWidth = 1200;

class Responsive {
  Responsive._();

  // ── Breakpoint helpers ──────────────────────────────────────────────────────

  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < _kTabletBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= _kTabletBreakpoint && w < _kDesktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _kDesktopBreakpoint;

  static bool isTabletOrLarger(BuildContext context) =>
      MediaQuery.of(context).size.width >= _kTabletBreakpoint;

  // ── Value helpers ───────────────────────────────────────────────────────────

  /// Returns [tablet] on tablet/desktop, [phone] otherwise.
  static T value<T>(BuildContext context, {required T phone, required T tablet}) =>
      isTabletOrLarger(context) ? tablet : phone;

  /// Returns a value interpolated across phone / tablet / desktop.
  static T valueTriple<T>(
    BuildContext context, {
    required T phone,
    required T tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return phone;
  }

  // ── Grid helpers ────────────────────────────────────────────────────────────

  /// Cross-axis count for genre / category grids.
  static int genreGridColumns(BuildContext context) =>
      valueTriple(context, phone: 2, tablet: 3, desktop: 4);

  /// Cross-axis count for music / album grids.
  static int musicGridColumns(BuildContext context) =>
      valueTriple(context, phone: 2, tablet: 3, desktop: 5);

  // ── Card size helpers ───────────────────────────────────────────────────────

  static double musicCardWidth(BuildContext context) =>
      value(context, phone: 160, tablet: 200);

  static double artistCardWidth(BuildContext context) =>
      value(context, phone: 140, tablet: 175);

  static double podcastCardWidth(BuildContext context) =>
      value(context, phone: 160, tablet: 200);

  static double podcastCardImageHeight(BuildContext context) =>
      value(context, phone: 100, tablet: 130);

  // ── Navigation helpers ──────────────────────────────────────────────────────

  /// Whether to show the NavigationRail (tablet) instead of BottomNav (phone).
  static bool useNavigationRail(BuildContext context) =>
      isTabletOrLarger(context);

  // ── Mini player ─────────────────────────────────────────────────────────────

  static double miniPlayerHeight(BuildContext context) =>
      value(context, phone: 68, tablet: 88);
}
