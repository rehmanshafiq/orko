import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_revamped_theme.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// Confirm payment — layout matches product reference.
class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  static const double _totalAmount = 28.01;

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int _selectedIndex = 0;

  static List<
      ({
        String title,
        String subtitle,
        IconData icon,
        Color iconBg,
        Color? iconColor,
      })> _paymentMethods(AppRevampedTheme t) {
    return [
      (
        title: 'Visa card',
        subtitle: '•••• •••• •••• 4291',
        icon: Icons.credit_card_rounded,
        iconBg: t.paymentIconBlueBg,
        iconColor: t.paymentPrimaryGreen,
      ),
      (
        title: 'EasyPaisa',
        subtitle: 'Linked Mobile Wallet',
        icon: Icons.account_balance_wallet_rounded,
        iconBg: t.mintBadgeBackground,
        iconColor: t.paymentPrimaryGreen,
      ),
      (
        title: 'JazzCash',
        subtitle: 'Instant Pay Enabled',
        icon: Icons.payments_rounded,
        iconBg: t.paymentIconRedBg,
        iconColor: t.paymentIconRed,
      ),
      (
        title: 'Cash',
        subtitle: 'Pay at Counter',
        icon: Icons.money_rounded,
        iconBg: t.totalBoxBackground,
        iconColor: t.textPrimary,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    final paymentMethods = _paymentMethods(t);
    return Scaffold(
      backgroundColor: t.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    8.verticalSpace,
                    _PaymentHeader(onSearch: () => context.push('/search')),
                    20.verticalSpace,
                    AppText(
                      'Confirm Payment',
                      color: t.textPrimary,
                      fontSize: FontSizes.font26Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    20.verticalSpace,
                    const _PaymentSummaryCard(),
                    28.verticalSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText(
                          'Payment Method',
                          color: t.textPrimary,
                          fontSize: FontSizes.font18Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: AppText(
                            'Add New',
                            color: t.paymentPrimaryGreen,
                            fontSize: FontSizes.font14Sp,
                            fontWeight: FontWeights.weight700,
                          ),
                        ),
                      ],
                    ),
                    16.verticalSpace,
                    ...List.generate(paymentMethods.length, (index) {
                      final method = paymentMethods[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == paymentMethods.length - 1 ? 0 : 12.h,
                        ),
                        child: _PaymentMethodTile(
                          title: method.title,
                          subtitle: method.subtitle,
                          icon: method.icon,
                          iconBackground: method.iconBg,
                          iconColor: method.iconColor ?? t.textPrimary,
                          selected: _selectedIndex == index,
                          onTap: () => setState(() => _selectedIndex = index),
                        ),
                      );
                    }),
                    24.verticalSpace,
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                child: _ContinuePaymentButton(
                  onPressed: () => context.push(
                    '/booking-confirmation',
                    extra: PaymentMethodScreen._totalAmount.toInt(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 20.r,
          backgroundColor: t.avatarBackground,
          child: Icon(
            Icons.person_rounded,
            color: t.textMuted,
            size: 22.sp,
          ),
        ),
        Expanded(
          child: Center(
            child: AppText(
              'HUBCO',
              color: t.paymentPrimaryGreen,
              fontSize: FontSizes.font22Sp,
              fontWeight: FontWeights.weight700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        IconButton(
          onPressed: onSearch,
          icon: Icon(
            Icons.search_rounded,
            color: t.paymentPrimaryGreen,
            size: 24.sp,
          ),
        ),
      ],
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard();

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'SESSION ID',
                      color: context.revampedTheme.textMuted,
                      fontSize: FontSizes.font10Sp,
                      fontWeight: FontWeights.weight700,
                      letterSpacing: 0.8,
                    ),
                    4.verticalSpace,
                    AppText(
                      '#HB-8829-EV',
                      color: context.revampedTheme.textPrimary,
                      fontSize: FontSizes.font16Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: context.revampedTheme.mintBadgeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AppText(
                  'FAST CHARGE',
                  color: context.revampedTheme.paymentPrimaryGreen,
                  fontSize: FontSizes.font10Sp,
                  fontWeight: FontWeights.weight700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          18.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  label: 'ENERGY DELIVERED',
                  value: '54.2',
                  unit: 'kWh',
                ),
              ),
              Expanded(
                child: _MetricBlock(
                  label: 'DURATION',
                  value: '42m',
                  unit: '12s',
                ),
              ),
            ],
          ),
          18.verticalSpace,
          const _CostLine(
            label: 'Base Rate (0.45/kWh)',
            value: 'PKR 24.39',
          ),
          10.verticalSpace,
          const _CostLine(
            label: 'Station Parking Fee',
            value: 'PKR 2.50',
          ),
          10.verticalSpace,
          const _CostLine(
            label: 'EV Tax & Surcharge',
            value: 'PKR 1.12',
          ),
          16.verticalSpace,
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.revampedTheme.totalBoxBackground,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  'Total Amount',
                  color: context.revampedTheme.textPrimary,
                  fontSize: FontSizes.font15Sp,
                  fontWeight: FontWeights.weight700,
                ),
                AppText(
                  'PKR ${PaymentMethodScreen._totalAmount.toStringAsFixed(2)}',
                  color: context.revampedTheme.paymentPrimaryGreen,
                  fontSize: FontSizes.font18Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          color: context.revampedTheme.textMuted,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight700,
          letterSpacing: 0.6,
        ),
        6.verticalSpace,
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AppText(
              value,
              color: context.revampedTheme.textPrimary,
              fontSize: FontSizes.font22Sp,
              fontWeight: FontWeights.weight700,
            ),
            4.horizontalSpace,
            AppText(
              unit,
              color: context.revampedTheme.textMuted,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight500,
            ),
          ],
        ),
      ],
    );
  }
}

class _CostLine extends StatelessWidget {
  const _CostLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          color: context.revampedTheme.textMuted,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight400,
        ),
        AppText(
          value,
          color: context.revampedTheme.textPrimary,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight600,
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: t.cardBackground,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected ? t.paymentPrimaryGreen : AppColors.transparentColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: t.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: iconColor, size: 22.sp),
              ),
              14.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      title,
                      color: context.revampedTheme.textPrimary,
                      fontSize: FontSizes.font15Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    4.verticalSpace,
                    AppText(
                      subtitle,
                      color: context.revampedTheme.textMuted,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: t.paymentPrimaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: t.textOnBrand,
                    size: 16.sp,
                  ),
                )
              else
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: t.disabledButtonGrey,
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinuePaymentButton extends StatelessWidget {
  const _ContinuePaymentButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              t.continueGradientStart,
              t.paymentPrimaryGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: t.paymentPrimaryGreen.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparentColor,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    'Continue Payment',
                    color: t.textOnBrand,
                    fontSize: FontSizes.font16Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                  8.horizontalSpace,
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: t.textOnBrand,
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
