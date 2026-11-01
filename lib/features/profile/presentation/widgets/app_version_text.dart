import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Installed app version (e.g. "Version 1.0.1") shown at the
/// bottom of the Settings tab, so users can report it with support requests.
class AppVersionText extends StatefulWidget {
  const AppVersionText({super.key});

  @override
  State<AppVersionText> createState() => _AppVersionTextState();
}

class _AppVersionTextState extends State<AppVersionText> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return FutureBuilder<PackageInfo>(
      future: _packageInfo,
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: AppText(
            'Version ${info.version}',
            textAlign: TextAlign.center,
            color: ui.textMuted,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
        );
      },
    );
  }
}
