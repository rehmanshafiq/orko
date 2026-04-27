import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_view_widget.dart';
import '../view/splash_mobile_view.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveView(
      mobile: SplashMobileView(),
    );
  }
}
