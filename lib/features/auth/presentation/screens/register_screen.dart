import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_state.dart';

/// Register screen.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Demo User');
  final _phoneController = TextEditingController(text: '300 1234567');
  final _emailController = TextEditingController(text: 'demo@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _confirmPasswordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isTermsAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_isTermsAccepted) {
        AppHelpers.showSnackBar(context, 'Please accept terms and conditions', isError: true);
        return;
      }
      context.read<AuthCubit>().register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            AppHelpers.showSnackBar(context, state.message, isError: true);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: AppUtils.horizontal24Padding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    12.verticalSpace,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        padding: AppUtils.zeroPadding,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.arrow_back,
                          color: ui.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                    10.verticalSpace,
                    AppText(
                      'Create Account',
                      textAlign: TextAlign.center,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font28Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    6.verticalSpace,
                    AppText(
                      'Join HGL and start your green journey.',
                      textAlign: TextAlign.center,
                      color: ui.textMuted,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                    16.verticalSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStepperDot(ui, isActive: true),
                        8.horizontalSpace,
                        _buildStepperDot(ui, isActive: false),
                      ],
                    ),
                    24.verticalSpace,
                    _buildField(
                      ui,
                      hintText: 'Full Name',
                      controller: _nameController,
                      validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.hintColor, size: 18),
                    ),
                    12.verticalSpace,
                    Row(
                      children: [
                        8.horizontalSpace,
                        AppText(
                          'Phone Number',
                          color: ui.textPrimary,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight500,
                        ),
                      ],
                    ),
                    8.verticalSpace,
                    _buildPhoneField(ui),
                    12.verticalSpace,
                    _buildField(
                      ui,
                      hintText: 'Email Address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: AppHelpers.validateEmail,
                      prefixIcon: const Icon(Icons.mail_outline, color: AppColors.hintColor, size: 18),
                    ),
                    12.verticalSpace,
                    _buildField(
                      ui,
                      hintText: 'Password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: AppHelpers.validatePassword,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.hintColor,
                          size: 18,
                        ),
                      ),
                    ),
                    6.verticalSpace,
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2.r),
                      child: LinearProgressIndicator(
                        value: 0.8,
                        minHeight: 3,
                        color: AppColors.primaryDarkColor,
                        backgroundColor: ui.progressTrack,
                      ),
                    ),
                    4.verticalSpace,
                    AppText(
                      'Strong',
                      color: AppColors.primaryDarkColor,
                      fontSize: FontSizes.font10Sp,
                      fontWeight: FontWeights.weight500,
                    ),
                    10.verticalSpace,
                    _buildField(
                      ui,
                      hintText: 'Confirm Password',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onRegister(),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Confirm password is required';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    20.verticalSpace,
                    Row(
                      children: [
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: Checkbox(
                            value: _isTermsAccepted,
                            onChanged: (value) => setState(() => _isTermsAccepted = value ?? false),
                            fillColor: WidgetStateProperty.resolveWith<Color>(
                              (states) => states.contains(WidgetState.selected)
                                  ? AppColors.primaryDarkColor
                                  : AppColors.transparentColor,
                            ),
                            side: BorderSide(color: ui.inputBorder),
                          ),
                        ),
                        10.horizontalSpace,
                        Expanded(
                          child: Wrap(
                            children: [
                              AppText(
                                'I agree to the ',
                                color: ui.textPrimary.withValues(alpha: 0.75),
                                fontSize: FontSizes.font12Sp,
                                fontWeight: FontWeights.weight400,
                              ),
                              AppText(
                                'Terms and Conditions',
                                color: AppColors.primaryDarkColor,
                                fontSize: FontSizes.font12Sp,
                                fontWeight: FontWeights.weight500,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    18.verticalSpace,
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDarkColor.withValues(alpha: 0.35),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: PrimaryButtonWidget(
                        text: state is AuthLoading ? 'Please wait...' : 'Continue',
                        onPress: _onRegister,
                        isEnabled: state is! AuthLoading,
                        buttonHeight: 52.h,
                        cornerRadius: 12.r,
                        buttonColor: AppColors.primaryDarkColor,
                        textColor: AppColors.whiteColor,
                        fontSize: FontSizes.font16Sp,
                        fontWeight: FontWeights.weight600,
                      ),
                    ),
                    32.verticalSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          'Already have an account? ',
                          color: ui.textMuted,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight400,
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: AppText(
                            'Sign In',
                            color: AppColors.primaryDarkColor,
                            fontSize: FontSizes.font12Sp,
                            fontWeight: FontWeights.weight600,
                          ),
                        ),
                      ],
                    ),
                    20.verticalSpace,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepperDot(AppUiColors ui, {required bool isActive}) {
    return Container(
      height: 14.h,
      width: 14.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? AppColors.primaryDarkColor
            : ui.textSecondary.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _buildPhoneField(AppUiColors ui) {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      validator: (value) => (value == null || value.trim().isEmpty) ? 'Phone number is required' : null,
      maxLength: 11,
      style: TextStyle(
        color: ui.textPrimary,
        fontSize: FontSizes.font14Sp,
        fontWeight: FontWeights.weight500,
      ),
      decoration: InputDecoration(
        hintText: 'Phone Number',
        hintStyle: TextStyle(
          color: AppColors.hintColor,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight400,
        ),
        filled: true,
        fillColor: ui.inputFill,
        contentPadding: EdgeInsets.zero,
        prefixIconConstraints: BoxConstraints(minWidth: 0.w, minHeight: 0.h),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🇵🇰', style: TextStyle(fontSize: 14)),
              6.horizontalSpace,
              AppText(
                '+92',
                color: ui.textPrimary.withValues(alpha: 0.9),
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight500,
              ),
              10.horizontalSpace,
              Container(
                height: 16.h,
                width: 1,
                color: ui.inputBorder,
              ),
            ],
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: ui.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primaryDarkColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.redColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.redColor),
        ),
      ),
    );
  }

  Widget _buildField(
    AppUiColors ui, {
    required String hintText,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      maxLength: 40,
      style: TextStyle(
        color: ui.textPrimary,
        fontSize: FontSizes.font14Sp,
        fontWeight: FontWeights.weight500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColors.hintColor,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight400,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: ui.inputFill,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: ui.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primaryDarkColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.redColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.redColor),
        ),
      ),
    );
  }
}
