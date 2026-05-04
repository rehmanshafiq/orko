import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_state.dart';

/// Login screen — uses BlocConsumer to react to auth state changes.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: '300 1234567');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    return null;
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
                    50.verticalSpace,
                    _buildHeader(ui),
                    30.verticalSpace,
                    _buildPhoneNumberField(ui),
                    14.verticalSpace,
                    _buildPasswordField(ui),
                    8.verticalSpace,
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: AppUtils.zeroPadding,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: AppText(
                          'Forgot Password?',
                          color: AppColors.primaryDarkColor,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight500,
                        ),
                      ),
                    ),
                    20.verticalSpace,
                    _buildSignInButton(state, ui),
                    28.verticalSpace,
                    _buildContinueWith(ui),
                    18.verticalSpace,
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                              imagePath: 'assets/icons/google_logo.png',
                            text: 'Google',
                            onTap: () {},
                          ),
                        ),
                        14.horizontalSpace,
                        Expanded(
                          child: _SocialButton(
                            icon: Icons.apple,
                            text: 'Apple',
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    60.verticalSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(
                          "Don't have an account? ",
                          color: ui.textMuted,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight400,
                        ),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: AppText(
                            'Sign Up',
                            color: AppColors.primaryDarkColor,
                            fontSize: FontSizes.font12Sp,
                            fontWeight: FontWeights.weight600,
                          ),
                        ),
                      ],
                    ),
                    24.verticalSpace,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppUiColors ui) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          width: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryDarkColor.withValues(alpha: 0.28),
                      AppColors.primaryDarkColor.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDarkColor.withValues(alpha: 0.45),
                      blurRadius: 22,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.bolt,
                color: AppColors.primaryDarkColor,
                size: 42,
              ),
            ],
          ),
        ),
        2.verticalSpace,
        AppText(
          'HGL',
          color: ui.textPrimary,
          fontSize: FontSizes.font24Sp,
          fontWeight: FontWeights.weight400,
        ),
        AppText(
          'HUBCO Green Limited',
          color: ui.textMuted,
          fontSize: FontSizes.font4Sp,
          fontWeight: FontWeights.weight400,
        ),
        20.verticalSpace,
        AppText(
          'Welcome Back',
          textAlign: TextAlign.center,
          color: ui.textPrimary,
          fontSize: FontSizes.font28Sp,
          fontWeight: FontWeights.weight600,
        ),
        2.verticalSpace,
        AppText(
          'Sign in to continue charging.',
          textAlign: TextAlign.center,
          color: ui.textMuted,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight400,
        ),
      ],
    );
  }

  Widget _buildPhoneNumberField(AppUiColors ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Phone Number',
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight500,
        ),
        8.verticalSpace,
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: _validatePhoneNumber,
          maxLength: 11,
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
          ),
          decoration: InputDecoration(
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
                  10.horizontalSpace,
                  const Icon(Icons.phone_outlined, color: AppColors.hintColor, size: 18),
                ],
              ),
            ),
            hintText: '300 1234567',
            hintStyle: TextStyle(
              color: AppColors.hintColor,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight400,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ui.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryDarkColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.redColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.redColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(AppUiColors ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Password',
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight500,
        ),
        8.verticalSpace,
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          validator: AppHelpers.validatePassword,
          onFieldSubmitted: (_) => _onLogin(),
          maxLength: 40,
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
          ),
          decoration: _inputDecoration(
            ui: ui,
            hintText: '**********',
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.hintColor,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required AppUiColors ui,
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
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
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ui.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryDarkColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.redColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.redColor),
      ),
    );
  }

  Widget _buildSignInButton(AuthState state, AppUiColors ui) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkColor.withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: ui.socialButtonShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PrimaryButtonWidget(
        text: state is AuthLoading ? 'Signing In...' : 'Sign In',
        onPress: _onLogin,
        isEnabled: state is! AuthLoading,
        buttonHeight: 52.h,
        cornerRadius: 12.r,
        buttonColor: AppColors.primaryDarkColor,
        textColor: AppColors.whiteColor,
        fontSize: FontSizes.font16Sp,
        fontWeight: FontWeights.weight400,
      ),
    );
  }

  Widget _buildContinueWith(AppUiColors ui) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: ui.dividerLine,
            thickness: 1,
          ),
        ),
        Padding(
          padding: AppUtils.horizontal14Padding,
          child: AppText(
            'or continue with',
            color: ui.textMuted,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
        ),
        Expanded(
          child: Divider(
            color: ui.dividerLine,
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String text;
  final VoidCallback onTap;

  const _SocialButton({
    this.icon,
    this.imagePath,
    required this.text,
    required this.onTap,
  }) : assert(icon != null || imagePath != null, 'Provide icon or imagePath');

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final Widget leadingIcon =
        imagePath != null
            ? AppPngImageView(
                appImagePath: imagePath!,
                height: 22.h,
                width: 22.w,
              )
            : Icon(icon, size: 24.r);

    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: ui.textPrimary,
        side: BorderSide(
          color: ui.inputBorder,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      ),
      icon: leadingIcon,
      label: AppText(
        text,
        color: ui.textPrimary,
        fontSize: FontSizes.font14Sp,
        fontWeight: FontWeights.weight500,
      ),
    );
  }
}
