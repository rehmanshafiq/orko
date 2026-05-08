import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/search/presentation/cubit/search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(const SearchInitial());

  final TextEditingController searchController = TextEditingController();

  void clearSearch() {
    searchController.clear();
  }

  @override
  Future<void> close() {
    searchController.dispose();
    return super.close();
  }
}

