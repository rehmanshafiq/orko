import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/services/analytics_service.dart';
import 'package:orko_hubco/core/services/analytics_user_properties.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_state.dart';
import 'package:orko_hubco/features/auth/presentation/widgets/forgot_password_sheet.dart';

/// Login screen — uses BlocConsumer to react to auth state changes.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  /// Which social provider triggered the in-flight [AuthLoading], so only that
  /// button shows a spinner (phone login sets none). Reset whenever we leave
  /// the loading state.
  _SocialProvider? _loadingProvider;

  static const String _countryCode = '+92';

  /// Apple sign-in is only offered on iOS; Android keeps the Google + Guest
  /// layout. (iOS min deployment is 13+, so the API is always available here.)
  bool get _showAppleSignIn => Platform.isIOS;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    context.read<AuthCubit>().login(
          phoneNumber: _phoneController.text.trim(),
          countryCode: _countryCode,
          password: _passwordController.text,
        );
  }

  String? _validatePhoneNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^3\d{9}$').hasMatch(digits)) {
      return 'Enter a valid number, e.g. 3001234567';
    }
    return null;
  }

  /// Starts the Google sign-in flow. The cubit drives the rest: success emits
  /// [AuthAuthenticated] (handled by the listener → `/home`); cancellation
  /// resets silently; failures surface a snackbar via [AuthError].
  void _onGoogleLogin() {
    FocusScope.of(context).unfocus();
    setState(() => _loadingProvider = _SocialProvider.google);
    context.read<AuthCubit>().loginWithGoogle();
  }

  /// Starts the Sign in with Apple flow (iOS only). Mirrors [_onGoogleLogin]:
  /// the cubit reuses the same backend endpoint as Google, so success emits
  /// [AuthAuthenticated]; cancellation resets silently; failures surface a
  /// snackbar via [AuthError].
  void _onAppleLogin() {
    FocusScope.of(context).unfocus();
    setState(() => _loadingProvider = _SocialProvider.apple);
    context.read<AuthCubit>().loginWithApple();
  }

  /// Opens the forgot-password flow (request OTP by email → reset password).
  /// On success a confirmation snackbar is shown.
  Future<void> _onForgotPassword() async {
    FocusScope.of(context).unfocus();
    final message = await ForgotPasswordSheet.show(context);
    if (!mounted || message == null) return;
    AppHelpers.showSnackBar(context, message);
  }

  /// Enters the app as a guest. Guests can browse but not book; the guest flag
  /// is cleared automatically once they log in or sign up.
  Future<void> _onContinueAsGuest() async {
    await AppStorage.setGuest(true);
    sl<AnalyticsService>().logEvent('guest_mode_entered');
    sl<AnalyticsUserProperties>().setGuest();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          // Once we leave the loading state, no social button should spin.
          if (state is! AuthLoading && _loadingProvider != null) {
            setState(() => _loadingProvider = null);
          }
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
                autovalidateMode: _autovalidateMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    26.verticalSpace,
                    _buildHeader(ui),
                    24.verticalSpace,
                    _buildPhoneNumberField(ui),
                    14.verticalSpace,
                    _buildPasswordField(ui),
                    8.verticalSpace,
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _onForgotPassword,
                        style: TextButton.styleFrom(
                          padding: AppUtils.zeroPadding,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: AppText(
                          'Forgot Password?',
                          color: ui.textMuted,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight500,
                        ),
                      ),
                    ),
                    16.verticalSpace,
                    _buildSignInButton(state, ui),
                    20.verticalSpace,
                    _buildContinueWith(ui),
                    16.verticalSpace,
                    _buildSocialButtons(state),
                    30.verticalSpace,
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
                            color: ui.brandPrimary,
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
    final logoWidth = MediaQuery.sizeOf(context).width * 0.45;

    return Column(
      children: [
        AppPngImageView(
          appImagePath: ui.isLight ? AppImages.hubcoLogoLight : AppImages.hubcoLogo,
          width: logoWidth,
        ),
        // 20.verticalSpace,
        // AppText(
        //   'Welcome Back',
        //   textAlign: TextAlign.center,
        //   color: ui.textPrimary,
        //   fontSize: FontSizes.font28Sp,
        //   fontWeight: FontWeights.weight600,
        // ),
        // 2.verticalSpace,
        // AppText(
        //   'Sign in to continue charging.',
        //   textAlign: TextAlign.center,
        //   color: ui.textMuted,
        //   fontSize: FontSizes.font12Sp,
        //   fontWeight: FontWeights.weight400,
        // ),
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
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: _validatePhoneNumber,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 10,
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
            hintText: 'Phone Number',
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
              borderSide: BorderSide(color: ui.brandPrimary),
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
            hintText: 'Password',
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
        borderSide: BorderSide(color: ui.brandPrimary),
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
            color: ui.brandPrimary.withValues(alpha: 0.35),
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
        buttonHeight: 38.h,
        cornerRadius: 24.r,
        gradientColors: const [
          AppColors.primaryDarkColor,
          AppColors.primaryDarkButtonColor,
        ],
        textColor: AppColors.whiteColor,
        fontSize: FontSizes.font16Sp,
        fontWeight: FontWeights.weight400,
      ),
    );
  }

  /// Social / guest buttons.
  ///
  /// - **iOS:** Apple + Google side by side, with Guest full-width underneath
  ///   (Apple's guidelines want Sign in with Apple presented prominently).
  /// - **Android:** the original Google + Guest row (no Apple button).
  Widget _buildSocialButtons(AuthState state) {
    final bool isBusy = state is AuthLoading;

    final googleButton = _SocialButton(
      imagePath: 'assets/icons/ic_google.png',
      text: 'Google',
      isLoading: _loadingProvider == _SocialProvider.google,
      enabled: !isBusy,
      onTap: _onGoogleLogin,
    );

    final guestButton = _SocialButton(
      icon: Icons.person_outline,
      text: 'Guest',
      enabled: !isBusy,
      onTap: _onContinueAsGuest,
    );

    if (!_showAppleSignIn) {
      return Row(
        children: [
          Expanded(child: googleButton),
          14.horizontalSpace,
          Expanded(child: guestButton),
        ],
      );
    }

    final appleButton = _SocialButton(
      icon: Icons.apple,
      text: 'Apple',
      isLoading: _loadingProvider == _SocialProvider.apple,
      enabled: !isBusy,
      onTap: _onAppleLogin,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: appleButton),
            14.horizontalSpace,
            Expanded(child: googleButton),
          ],
        ),
        14.verticalSpace,
        guestButton,
      ],
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

/// Identifies which social provider a sign-in is in flight for, so only the
/// tapped button shows a spinner.
enum _SocialProvider { google, apple }

class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String text;
  final VoidCallback onTap;
  final bool isLoading;
  final bool enabled;

  const _SocialButton({
    this.icon,
    this.imagePath,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
  }) : assert(icon != null || imagePath != null, 'Provide icon or imagePath');

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final Widget leadingIcon = isLoading
        ? SizedBox(
            height: 19.r,
            width: 19.r,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ui.brandPrimary,
            ),
          )
        : imagePath != null
            ? AppPngImageView(
                appImagePath: imagePath!,
                height: 26.h,
                width: 26.w,
              )
            : Icon(icon, size: 19.r);

    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: ui.textPrimary,
        side: BorderSide(color: ui.inputBorder),
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
