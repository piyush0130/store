import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) => mobile,
      tablet: (BuildContext context) => tablet,
      desktop: (BuildContext context) => desktop,
    );
  }
}
