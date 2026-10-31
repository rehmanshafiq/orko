import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/services/app_update/app_update_service.dart';
import 'package:orko_hubco/core/utils/app_toast.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

/// Blocking screen shown while the backend reports a force update
/// (`update_available: 2`). The router redirects every location here, and
/// back navigation is disabled, so the only way forward is updating.
class ForceUpdatePage extends StatefulWidget {
  const ForceUpdatePage({super.key});

  @override
  State<ForceUpdatePage> createState() => _ForceUpdatePageState();
}

class _ForceUpdatePageState extends State<ForceUpdatePage> {
  bool _opening = false;
  bool _storeFailed = false;

  Future<void> _onUpdate() async {
    setState(() => _opening = true);
    final service = AppUpdateService.instance;
    final opened = await service.openStore();
    if (!mounted) return;
    setState(() {
      _opening = false;
      _storeFailed = !opened;
    });
    if (!opened) {
      AppToast.error(
        'Couldn\'t open the ${service.storeName}. Please update the app '
        'from the ${service.storeName}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final storeName = AppUpdateService.instance.storeName;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ui.scaffoldBackground,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: AppPngImageView(
                    appImagePath: ui.isLight
                        ? AppImages.hubcoLogoLight
                        : AppImages.hubcoLogo,
                    width: MediaQuery.sizeOf(context).width * 0.4,
                  ),
                ),
                40.verticalSpace,
                Center(
                  child: Container(
                    height: 64.r,
                    width: 64.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ui.brandPrimary),
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      color: ui.brandPrimary,
                      size: 32.r,
                    ),
                  ),
                ),
                20.verticalSpace,
                AppText(
                  'Update Required',
                  textAlign: TextAlign.center,
                  color: ui.textPrimary,
                  fontSize: FontSizes.font22Sp,
                  fontWeight: FontWeights.weight700,
                ),
                10.verticalSpace,
                AppText(
                  'This version of the app is no longer supported. Please '
                  'update to the latest version to continue.',
                  textAlign: TextAlign.center,
                  color: ui.textMuted,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight400,
                ),
                if (_storeFailed) ...[
                  12.verticalSpace,
                  AppText(
                    'Couldn\'t open the $storeName. Please open the '
                    '$storeName and update the app manually.',
                    textAlign: TextAlign.center,
                    color: AppColors.removeColor,
                    fontSize: FontSizes.font13Sp,
                    fontWeight: FontWeights.weight400,
                  ),
                ],
                const Spacer(),
                PrimaryButtonWidget(
                  text: 'Update Now',
                  onPress: _onUpdate,
                  isLoading: _opening,
                  buttonHeight: 48.h,
                  cornerRadius: 24.r,
                  // Same dark-green gradient as the station detail "Book Slot" button.
                  gradientColors: const [
                    AppColors.primaryDarkColor,
                    AppColors.primaryDarkButtonColor,
                  ],
                  textColor: AppColors.whiteColor,
                  fontSize: FontSizes.font15Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
