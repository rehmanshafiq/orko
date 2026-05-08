import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_view_widget.dart';
import '../view/search_mobile_view.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveView(
      mobile: SearchMobileView(),
    );
  }
}

