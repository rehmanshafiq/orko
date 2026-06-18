import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';
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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  final bool _obscureConfirmPassword = true;
  bool _isTermsAccepted = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  static const String _countryCode = '+92';

  void _onRegister() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      // Surface errors live for every field after the first failed attempt.
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    if (!_isTermsAccepted) {
      AppHelpers.showSnackBar(context, 'Please accept terms and conditions', isError: true);
      return;
    }
    context.read<AuthCubit>().signUp(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          countryCode: _countryCode,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
  }

  // ── Validators ────────────────────────────────────────────────────────

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Name is required';
    if (name.length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r"^[a-zA-Z][a-zA-Z\s.'-]*$").hasMatch(name)) {
      return 'Enter a valid name';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^3\d{9}$').hasMatch(digits)) {
      return 'Enter a valid number, e.g. 3001234567';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      return 'Include at least one letter';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Include at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm password is required';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // ── Password strength ─────────────────────────────────────────────────

  /// Strength on a 0–1 scale derived from length and character variety.
  double get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    var score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'\d').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$&*~%^()\-_=+]').hasMatch(p)) score++;
    return score / 5;
  }

  String get _passwordStrengthLabel {
    final s = _passwordStrength;
    if (s == 0) return '';
    if (s < 0.4) return 'Weak';
    if (s < 0.8) return 'Medium';
    return 'Strong';
  }

  Color _passwordStrengthColor(AppUiColors ui) {
    final s = _passwordStrength;
    if (s < 0.4) return AppColors.redColor;
    if (s < 0.8) return AppColors.ratingStarColor;
    return ui.brandPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is SignUpSuccess) {
            context.push(
              '/verify-otp',
              extra: {
                'phoneNumber':
                    _phoneController.text.replaceAll(RegExp(r'\s+'), ''),
                'countryCode': _countryCode,
              },
            );
          } else if (state is AuthAuthenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            AppHelpers.showSnackBar(context, state.message, isError: true);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 24.w, top: 4.h, right: 24.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.arrow_back,
                        color: ui.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppUtils.horizontal24Padding.copyWith(top: 4.h),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autovalidateMode,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: AppPngImageView(
                              appImagePath: ui.isLight ? AppImages.hubcoLogoLight : AppImages.hubcoLogo,
                              width: MediaQuery.sizeOf(context).width * 0.45,
                            ),
                          ),
                          12.verticalSpace,
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
                    _buildField(
                      ui,
                      hintText: 'Full Name',
                      controller: _nameController,
                      validator: _validateName,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[a-zA-Z\s.'-]"),
                        ),
                      ],
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.hintColor, size: 18),
                    ),
                    8.verticalSpace,
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
                    8.verticalSpace,
                    _buildField(
                      ui,
                      hintText: 'Email Address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: AppHelpers.validateEmail,
                      prefixIcon: const Icon(Icons.mail_outline, color: AppColors.hintColor, size: 18),
                    ),
                    8.verticalSpace,
                    _buildField(
                      ui,
                      hintText: 'Password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      onChanged: (_) => setState(() {}),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.hintColor,
                          size: 18,
                        ),
                      ),
                    ),
                    if (_passwordController.text.isNotEmpty) ...[
                      6.verticalSpace,
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2.r),
                        child: LinearProgressIndicator(
                          value: _passwordStrength,
                          minHeight: 3,
                          color: _passwordStrengthColor(ui),
                          backgroundColor: ui.progressTrack,
                        ),
                      ),
                      4.verticalSpace,
                      AppText(
                        _passwordStrengthLabel,
                        color: _passwordStrengthColor(ui),
                        fontSize: FontSizes.font10Sp,
                        fontWeight: FontWeights.weight500,
                      ),
                    ],
                    8.verticalSpace,
                    _buildField(
                      ui,
                      hintText: 'Confirm Password',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onRegister(),
                      validator: _validateConfirmPassword,
                    ),
                    8.verticalSpace,
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
                                  ? ui.brandPrimary
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
                                color: ui.brandPrimary,
                                fontSize: FontSizes.font12Sp,
                                fontWeight: FontWeights.weight500,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    18.verticalSpace,
                    PrimaryButtonWidget(
                      text: state is AuthLoading ? 'Please wait...' : 'Continue',
                      onPress: _onRegister,
                      isEnabled: state is! AuthLoading,
                      buttonHeight: 38.h,
                      cornerRadius: 24.r,
                      gradientColors: const [
                        AppColors.primaryDarkColor,
                        AppColors.primaryDarkButtonColor,
                      ],
                      textColor: AppColors.whiteColor,
                      fontSize: FontSizes.font16Sp,
                      fontWeight: FontWeights.weight600,
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
                            color: ui.brandPrimary,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneField(AppUiColors ui) {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      validator: _validatePhone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 10,
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
          borderSide: BorderSide(color: ui.brandPrimary),
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
    ValueChanged<String>? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
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
          borderSide: BorderSide(color: ui.brandPrimary),
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
