import 'package:flutter/material.dart';
import 'package:orko_hubco/features/onboarding/presentation/view/onboarding_mobile_view.dart';
import '../../../../core/utils/responsive_view_widget.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveView(
      mobile: OnboardingMobileView(),
    );
  }
}
