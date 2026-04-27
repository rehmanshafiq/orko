
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ResponsiveView extends StatelessWidget {
  const ResponsiveView({
    super.key,
    required this.mobile,
    this.desktop,
    this.tablet,
  });

  final Widget mobile;
  final Widget? desktop;
  final Widget? tablet;

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      breakpoints:
      const ScreenBreakpoints(tablet: 600, desktop: 950, watch: 300),
      mobile: (context) => mobile,
      tablet: (context) => tablet ?? mobile,
      desktop: (context) => desktop ?? tablet ?? mobile,
    );
  }
}
