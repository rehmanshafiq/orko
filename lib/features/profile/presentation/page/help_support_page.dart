import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/features/profile/presentation/page/admin_support_page.dart';
import 'package:orko_hubco/features/profile/presentation/page/faq_page.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/section_card.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/settings_tab_body.dart';

/// Help & Support hub: two entries — FAQs and Admin Support — each opening its
/// own screen.
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: ui.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: ui.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: AppText(
          'Help & Support',
          color: ui.textPrimary,
          fontSize: FontSizes.font18Sp,
          fontWeight: FontWeights.weight700,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppUtils.horizontal16Padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              16.verticalSpace,
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccountTile(
                      icon: Icons.help_outline_rounded,
                      label: 'FAQs',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const FaqPage(),
                        ),
                      ),
                      // onTap: () {
                      //   Fluttertoast.showToast(
                      //     msg: 'Coming soon',
                      //     toastLength: Toast.LENGTH_SHORT,
                      //     gravity: ToastGravity.BOTTOM,
                      //   );
                      //   return;
                      // },
                    ),
                    const DividerLine(),
                    AccountTile(
                      icon: Icons.support_agent_rounded,
                      label: 'Admin Support',
                      onTap: () {
                        // Support is tied to the authenticated user — guests
                        // must sign in first.
                        if (AppStorage.isGuest) {
                          AuthRequiredDialog.show(
                            context,
                            feature: 'support',
                            message:
                                'You\'re browsing as a guest. Please log in or create an account to contact support.',
                          );
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AdminSupportPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
