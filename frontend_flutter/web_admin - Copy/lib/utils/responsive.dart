import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 850;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 850 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          return desktop;
        } else if (constraints.maxWidth >= 850) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}

// Extension để dễ dàng lấy thông tin responsive
extension ResponsiveExtension on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < 850;
  bool get isTablet => MediaQuery.of(this).size.width >= 850 && MediaQuery.of(this).size.width < 1100;
  bool get isDesktop => MediaQuery.of(this).size.width >= 1100;
  
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  // Responsive padding
  EdgeInsets get responsivePadding {
    if (isMobile) {
      return const EdgeInsets.all(16);
    } else if (isTablet) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }
  
  // Responsive spacing
  double get responsiveSpacing {
    if (isMobile) return 12;
    if (isTablet) return 16;
    return 20;
  }
  
  // Responsive font size
  double get responsiveTitleSize {
    if (isMobile) return 20;
    if (isTablet) return 24;
    return 28;
  }
  
  double get responsiveSubtitleSize {
    if (isMobile) return 14;
    if (isTablet) return 16;
    return 18;
  }
  
  double get responsiveBodySize {
    if (isMobile) return 12;
    if (isTablet) return 13;
    return 14;
  }
}