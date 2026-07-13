import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/services/local_storage_service.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/profile/domain/entities/profile_entity.dart';
import 'package:orko_hubco/features/profile/presentation/utils/profile_actions.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/section_card.dart';

class PersonalInfoCard extends StatelessWidget {
  const PersonalInfoCard({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final storage = sl<LocalStorageService>();
    final cachedUser = readCachedUser(storage);
    final isGuest = storage.isGuest || cachedUser == null;

    final displayName = isGuest
        ? 'Guest User'
        : (cachedUser.name.isNotEmpty ? cachedUser.name : profile.name);
    final displayEmail = isGuest
        ? 'Sign in to sync your account'
        : (cachedUser.email.isNotEmpty ? cachedUser.email : profile.email);
    final displayPhone = isGuest
        ? null
        : formatCachedUserPhone(cachedUser) ?? profile.phone;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Personal Information',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font16Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
              PrimaryButtonWidget(
                text: 'Edit',
                onPress: () => openEditProfile(context, cachedUser, isGuest),
                buttonWidth: 88.w,
                buttonHeight: 38.h,
                cornerRadius: 24.r,
                buttonColor: ui.editButtonColor,
                strokeColor: ui.borderSubtle,
                textColor: ui.textPrimary,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight600,
              ),
            ],
          ),
          14.verticalSpace,
          KeyValueRow(label: 'Full Name', value: displayName),
          const DividerLine(),
          KeyValueRow(label: 'Email', value: displayEmail),
          if (displayPhone != null && displayPhone.isNotEmpty) ...[
            const DividerLine(),
            KeyValueRow(label: 'Phone', value: displayPhone),
          ],
        ],
      ),
    );
  }
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              label,
              color: ui.textSecondary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight400,
            ),
          ),
          8.horizontalSpace,
          Expanded(
            flex: 3,
            child: AppText(
              value,
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight600,
              textAlign: TextAlign.end,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}
