import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/search/presentation/cubit/search_cubit.dart';
import '../../../../core/utils/responsive_view_widget.dart';
import '../view/search_mobile_view.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchCubit>()..init(),
      child: const ResponsiveView(
        mobile: SearchMobileView(),
      ),
    );
  }
}
