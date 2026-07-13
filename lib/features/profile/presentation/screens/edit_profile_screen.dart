import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/auth/data/models/user_model.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';
import 'package:orko_hubco/features/auth/domain/usecases/edit_user_profile_usecase.dart';
import 'package:orko_hubco/features/profile/presentation/screens/change_email_screen.dart';

/// Edit-profile form. Prefills from the cached [user], submits the
/// `edit_user_profile` API, and pops `true` on success (after which the cached
/// user has already been refreshed via `get_user`).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({required this.user, super.key});

  final UserModel user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  /// Fixed dial code shown as a prefix; defaults to Pakistan (+92).
  late final String _countryCode;

  bool _saving = false;

  /// True once the email has been changed via the OTP flow. Even if the user
  /// backs out without tapping "Save Changes", the profile view must refresh
  /// (the cached user was already updated), so we pop `true` on exit.
  bool _emailChanged = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    final code = u.countryCode?.trim() ?? '';
    _countryCode = code.isEmpty ? '+92' : code;
    _nameController = TextEditingController(text: u.name);
    _emailController = TextEditingController(text: u.email);
    // Strip a leading dial code if the stored number embedded it, so the field
    // only holds the local number next to the fixed prefix.
    _phoneController = TextEditingController(
      text: _localPhone(u.phoneNumber ?? '', _countryCode),
    );
  }

  /// Removes a leading dial code / `0` so the editable portion is just the
  /// local number (e.g. `+923001234567` or `03001234567` → `3001234567`).
  static String _localPhone(String raw, String code) {
    var value = raw.trim();
    if (value.isEmpty) return '';
    if (value.startsWith(code)) {
      value = value.substring(code.length);
    } else if (value.startsWith('+')) {
      value = value.replaceFirst(RegExp(r'^\+\d{1,3}'), '');
    }
    value = value.replaceAll(RegExp(r'\D'), '');
    if (value.startsWith('0')) value = value.replaceFirst(RegExp(r'^0+'), '');
    return value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Opens the OTP-based email-change flow. On success the screen returns the
  /// refreshed user (its cached copy is already updated), so we just reflect
  /// the new email in the read-only field.
  Future<void> _onChangeEmail() async {
    FocusScope.of(context).unfocus();
    final updated = await Navigator.of(context).push<UserEntity>(
      MaterialPageRoute<UserEntity>(
        builder: (_) => ChangeEmailScreen(
          currentEmail: _emailController.text.trim(),
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _emailController.text = updated.email;
      _emailChanged = true;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final result = await sl<EditUserProfileUseCase>()(
      EditUserProfileParams(
        name: _nameController.text,
        phoneNumber: _phoneController.text.trim(),
        countryCode: _countryCode,
      ),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.removeColor,
            ),
          );
      },
      (_) {
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return PopScope(
      // Intercept back so we can return whether anything changed. "Save Changes"
      // still pops `true` explicitly (bypassing this); this covers the case
      // where only the email was changed and the user backs out.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_emailChanged);
      },
      child: Scaffold(
      backgroundColor: ui.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: ui.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: ui.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: AppText(
          'Edit Profile',
          color: ui.textPrimary,
          fontSize: FontSizes.font18Sp,
          fontWeight: FontWeights.weight700,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _saving,
          child: SingleChildScrollView(
            padding: AppUtils.horizontal16Padding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  16.verticalSpace,
                  _LabeledField(
                    ui: ui,
                    label: 'Full Name',
                    controller: _nameController,
                    hintText: 'Enter your full name',
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Full name is required'
                        : null,
                  ),
                  16.verticalSpace,
                  _LabeledField(
                    ui: ui,
                    label: 'Email',
                    controller: _emailController,
                    hintText: 'Your email',
                    readOnly: true,
                    suffix: GestureDetector(
                      onTap: _saving ? null : _onChangeEmail,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: AppText(
                          'Change',
                          color: ui.brandPrimary,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                      ),
                    ),
                  ),
                  16.verticalSpace,
                  _LabeledField(
                    ui: ui,
                    label: 'Phone',
                    controller: _phoneController,
                    hintText: '3001234567',
                    prefixText: '$_countryCode ',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Phone number is required';
                      if (value.length < 7) return 'Enter a valid phone number';
                      return null;
                    },
                  ),
                  28.verticalSpace,
                  _saving
                      ? Container(
                          height: 48.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.r),
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primaryDarkColor,
                                AppColors.primaryDarkButtonColor,
                              ],
                            ),
                          ),
                          child: SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.whiteColor,
                            ),
                          ),
                        )
                      : PrimaryButtonWidget(
                          text: 'Save Changes',
                          onPress: _save,
                          buttonWidth: double.infinity,
                          buttonHeight: 48.h,
                          cornerRadius: 24.r,
                          gradientColors: const [
                            AppColors.primaryDarkColor,
                            AppColors.primaryDarkButtonColor,
                          ],
                          textColor: AppColors.whiteColor,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                  24.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// A labelled text field matching the app's input styling.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.ui,
    required this.label,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.inputFormatters,
    this.readOnly = false,
    this.prefixText,
    this.suffix,
  });

  final AppUiColors ui;
  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  /// When true the field is shown but cannot be edited (e.g. email).
  final bool readOnly;

  /// Fixed, non-editable text shown before the input (e.g. the dial code).
  final String? prefixText;

  /// Optional trailing widget inside the field (e.g. the email "Change" action).
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
        6.verticalSpace,
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          inputFormatters: inputFormatters,
          maxLines: 1,
          readOnly: readOnly,
          enableInteractiveSelection: !readOnly,
          style: TextStyle(
            color: readOnly ? ui.textSecondary : ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
            fontFamily: AppFonts.lexend,
          ),
          cursorColor: ui.brandPrimary,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly
                ? ui.inputFill.withValues(alpha: 0.5)
                : ui.inputFill,
            isDense: true,
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            prefixText: prefixText,
            prefixStyle: TextStyle(
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight600,
              fontFamily: AppFonts.lexend,
            ),
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.hintColor,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight400,
              fontFamily: AppFonts.lexend,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
            errorStyle: TextStyle(
              color: AppColors.redColor,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight400,
            ),
          ),
        ),
      ],
    );
  }
}
