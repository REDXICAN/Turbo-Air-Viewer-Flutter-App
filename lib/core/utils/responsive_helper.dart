// lib/core/utils/responsive_helper.dart
import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1800;

  // Get responsive value based on screen size
  static T getValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop(context) && largeDesktop != null) {
      return largeDesktop;
    }
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  // Get responsive padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getValue(
        context,
        mobile: 16,
        tablet: 24,
        desktop: 32,
        largeDesktop: 48,
      ),
      vertical: getValue(
        context,
        mobile: 16,
        tablet: 20,
        desktop: 24,
      ),
    );
  }

  // Get number of columns for grid layouts
  static int getGridColumns(BuildContext context) {
    return getValue(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
      largeDesktop: 6,
    );
  }

  // Get max width for content containers
  static double getMaxContentWidth(BuildContext context) {
    return getValue(
      context,
      mobile: double.infinity,
      tablet: double.infinity,
      desktop: double.infinity,
      largeDesktop: double.infinity,
    );
  }
}

// Responsive wrapper widget
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final width = maxWidth ?? ResponsiveHelper.getMaxContentWidth(context);
    
    if (width == double.infinity) {
      return child;
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }
}