import 'package:flutter/material.dart';
import 'app_ui.dart';

class CustomScaffoldWidget extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final PreferredSizeWidget? preferredSizeAppBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final Color? backgroundColor;
  final bool hasPadding;
  final bool? resizeToAvoidBottomInset;
  const CustomScaffoldWidget({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
    this.preferredSizeAppBar,
    this.hasPadding = false,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundColor,
    extendBodyBehindAppBar: extendBodyBehindAppBar,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? false,
    extendBody: extendBody,
    appBar: preferredSizeAppBar ?? appBar,
    floatingActionButton: floatingActionButton,
    bottomNavigationBar: bottomNavigationBar,
    body: hasPadding ? Padding(padding: AppUtils.horizontal24Padding, child: body) : body,
  );
}
