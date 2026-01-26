import 'package:flutter/material.dart';

class ResponsiveLayout {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1100;

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < mobileBreakpoint;
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= mobileBreakpoint && 
      MediaQuery.of(context).size.width < tabletBreakpoint;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= tabletBreakpoint;

  static int getGridCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 1;
    if (width < tabletBreakpoint) return 2;
    if (width < 1200) return 3;
    return 4;
  }
}
