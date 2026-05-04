import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

/// Payment method selection — matches product dark UI.
class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  static const double _subtotal = 450;
  static const double _serviceFee = 22;
  static double get _total => _subtotal + _serviceFee;

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final total = PaymentMethodScreen._total;
    final ui = AppUiColors.of(context);
    final bg = ui.scaffoldBackground;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparentColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: ui.textPrimary,
            size: 24.r,
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: AppText(
          'Payment Method',
          color: ui.textPrimary,
          fontSize: FontSizes.font18Sp,
          fontWeight: FontWeights.weight700,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: AppUtils.horizontal16Padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  8.verticalSpace,
                  _bookingSummaryCard(),
                  24.verticalSpace,
                  AppText(
                    'Choose Payment Method',
                    color: ui.textPrimary,
                    fontSize: FontSizes.font15Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                  14.verticalSpace,
                  _paymentOption(
                    selected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                    brand: _visaBrand(),
                    title: 'Visa Card',
                    subtitle: 'Visa card ending 4242',
                  ),
                  10.verticalSpace,
                  _paymentOption(
                    selected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                    brand: _easyPaisaBrand(),
                    title: 'EasyPaisa',
                    subtitle: 'EasyPaisa - 03001234567',
                  ),
                  10.verticalSpace,
                  _paymentOption(
                    selected: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                    brand: _jazzCashBrand(),
                    title: 'JazzCash',
                    subtitle: 'JazzCash - 03201234567',
                  ),
                  10.verticalSpace,
                  _paymentOption(
                    selected: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                    brand: _hglWalletBrand(),
                    title: 'HGL Wallet',
                    subtitle: 'HGL Wallet - Balance Rs 1200',
                  ),
                  10.verticalSpace,
                  _paymentOption(
                    selected: _selectedIndex == 4,
                    onTap: () => setState(() => _selectedIndex = 4),
                    brand: _cashBrand(),
                    title: 'Cash at Station',
                    subtitle: null,
                  ),
                  14.verticalSpace,
                  _addNewPaymentRow(),
                  24.verticalSpace,
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: AppUtils.horizontal16Padding.add(
                EdgeInsets.only(bottom: 12.h, top: 8.h),
              ),
              child: PrimaryButtonWidget(
                text: 'Proceed to Pay Rs ${total.toInt()}',
                onPress: () => context.push(
                  '/booking-confirmation',
                  extra: total.toInt(),
                ),
                buttonWidth: double.infinity,
                buttonHeight: 52.h,
                cornerRadius: 12.r,
                buttonColor: AppColors.primaryDarkColor,
                textColor: AppColors.whiteColor,
                fontSize: FontSizes.font15Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingSummaryCard() {
    final ui = AppUiColors.of(context);
    return Container(
      width: double.infinity,
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: ui.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'HGL Charging Hub M2',
            color: ui.textPrimary,
            fontSize: FontSizes.font16Sp,
            fontWeight: FontWeights.weight700,
          ),
          6.verticalSpace,
          AppText(
            'April 18 14:00-15:00',
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
          16.verticalSpace,
          _summaryRow('Subtotal', 'Rs ${PaymentMethodScreen._subtotal.toInt()}'),
          10.verticalSpace,
          _summaryRow('Service Fee', 'Rs ${PaymentMethodScreen._serviceFee.toInt()}'),
          14.verticalSpace,
          Divider(
            height: 1,
            thickness: 1,
            color: ui.borderSubtle,
          ),
          12.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Total',
                color: ui.textPrimary,
                fontSize: FontSizes.font15Sp,
                fontWeight: FontWeights.weight700,
              ),
              AppText(
                'Rs ${PaymentMethodScreen._total.toInt()}',
                color: ui.textPrimary,
                fontSize: FontSizes.font15Sp,
                fontWeight: FontWeights.weight700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    final ui = AppUiColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          color: ui.textSecondary,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight400,
        ),
        AppText(
          value,
          color: ui.textPrimary,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight500,
        ),
      ],
    );
  }

  Widget _paymentOption({
    required bool selected,
    required VoidCallback onTap,
    required Widget brand,
    required String title,
    String? subtitle,
  }) {
    final ui = AppUiColors.of(context);
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: ui.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: selected
                  ? AppColors.primaryDarkColor
                  : ui.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primaryDarkColor.withValues(alpha: 0.42),
                      blurRadius: 14,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _radioDot(selected),
              12.horizontalSpace,
              brand,
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      title,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight600,
                    ),
                    if (subtitle != null) ...[
                      4.verticalSpace,
                      AppText(
                        subtitle,
                        color: ui.textSecondary,
                        fontSize: FontSizes.font12Sp,
                        fontWeight: FontWeights.weight400,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _radioDot(bool selected) {
    final ui = AppUiColors.of(context);
    return Container(
      height: 22.r,
      width: 22.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.primaryDarkColor
              : ui.textSecondary.withValues(alpha: 0.45),
          width: 2,
        ),
        color: AppColors.transparentColor,
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              height: 10.r,
              width: 10.r,
              decoration: const BoxDecoration(
                color: AppColors.primaryDarkColor,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  Widget _visaBrand() {
    return Container(
      width: 44.w,
      height: 30.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        color: AppColors.mapPinBlueColor,
        border: Border.all(
          color: AppColors.whiteColor.withValues(alpha: 0.12),
        ),
      ),
      alignment: Alignment.center,
      child: AppText(
        'VISA',
        color: AppColors.whiteColor,
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight800,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _easyPaisaBrand() {
    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryDarkColor,
      ),
      alignment: Alignment.center,
      child: AppText(
        'e',
        color: AppColors.whiteColor,
        fontSize: FontSizes.font18Sp,
        fontWeight: FontWeights.weight700,
      ),
    );
  }

  Widget _jazzCashBrand() {
    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.maroonColor,
      ),
      alignment: Alignment.center,
      child: AppText(
        'J',
        color: AppColors.whiteColor,
        fontSize: FontSizes.font16Sp,
        fontWeight: FontWeights.weight800,
      ),
    );
  }

  Widget _hglWalletBrand() {
    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryDarkColor.withValues(alpha: 0.22),
        border: Border.all(color: AppColors.primaryDarkColor.withValues(alpha: 0.6)),
      ),
      child: Icon(
        Icons.account_balance_wallet_outlined,
        color: AppColors.primaryDarkColor,
        size: 20.r,
      ),
    );
  }

  Widget _cashBrand() {
    final ui = AppUiColors.of(context);
    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ui.innerCardBg,
      ),
      child: Icon(
        Icons.payments_rounded,
        color: ui.textPrimary.withValues(alpha: 0.9),
        size: 20.r,
      ),
    );
  }

  Widget _addNewPaymentRow() {
    final ui = AppUiColors.of(context);
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: ui.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: ui.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryDarkColor.withValues(alpha: 0.2),
                  border: Border.all(color: AppColors.primaryDarkColor),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.primaryDarkColor,
                  size: 24.r,
                ),
              ),
              12.horizontalSpace,
              AppText(
                'Add New Payment Method',
                color: ui.textPrimary,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
