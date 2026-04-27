import 'package:flutter/material.dart';
import 'package:orko_hubco/features/splash/view/splash_mobile_view.dart';
import '../../../core/utils/responsive_view_widget.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveView(
      mobile: SplashMobileView(),
    );
  }
}
