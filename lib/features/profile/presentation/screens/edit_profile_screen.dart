import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:orko_hubco/features/auth/data/models/user_model.dart';
import 'package:orko_hubco/features/auth/domain/entities/login_method.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';
import 'package:orko_hubco/features/auth/domain/usecases/edit_user_profile_usecase.dart';
import 'package:orko_hubco/features/profile/presentation/screens/change_email_screen.dart';
import 'package:orko_hubco/features/profile/presentation/screens/change_phone_screen.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/contact_change_widgets.dart';

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

  /// Dial code shown as a prefix; defaults to Pakistan (+92). Updated when the
  /// number is changed via the OTP flow.
  late String _countryCode;

  bool _saving = false;

  /// True once the email or phone has been changed via its OTP flow. Even if
  /// the user backs out without tapping "Save Changes", the profile view must
  /// refresh (the cached user was already updated), so we pop `true` on exit.
  bool _contactChanged = false;

  /// Set for Google / Apple sign-ins: the backend keys those accounts by the
  /// provider's email, so changing it would detach the account from future
  /// social logins. `null` when the email can be changed.
  late final String? _emailLockedBy;

  bool get _emailLocked => _emailLockedBy != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _countryCode = _dialCode(u.countryCode);
    _nameController = TextEditingController(text: u.name);
    _emailController = TextEditingController(text: u.email);
    _emailLockedBy = switch (sl<AuthLocalDataSource>().loginMethod) {
      LoginMethod.google => 'Google',
      LoginMethod.apple => 'Apple',
      LoginMethod.password || null => null,
    };
    // Strip a leading dial code if the stored number embedded it, so the field
    // only holds the local number next to the fixed prefix.
    _phoneController = TextEditingController(
      text: _localPhone(u.phoneNumber ?? '', _countryCode),
    );
  }

  /// Stored dial code as `+NN`, defaulting to Pakistan (+92).
  static String _dialCode(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? '+92' : '+$digits';
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
    if (_emailLocked || _saving) return;
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
      _contactChanged = true;
    });
  }

  /// Opens the OTP-based phone-change flow and reflects the verified number
  /// (the cached user is already updated by the verify call).
  Future<void> _onChangePhone() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final updated = await Navigator.of(context).push<UserEntity>(
      MaterialPageRoute<UserEntity>(
        builder: (_) => ChangePhoneScreen(
          currentPhone: _phoneController.text.trim(),
          countryCode: _countryCode,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _countryCode = _dialCode(updated.countryCode);
      _phoneController.text = _localPhone(
        updated.phoneNumber ?? '',
        _countryCode,
      );
      _contactChanged = true;
    });
    // Clear a stale "required" error from an earlier save attempt.
    _formKey.currentState?.validate();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    // Only the name is edited here; email and phone are updated through their
    // own OTP flows, so they're left out of the payload.
    final result = await sl<EditUserProfileUseCase>()(
      EditUserProfileParams(name: _nameController.text),
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
      // where only the email/phone was changed and the user backs out.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_contactChanged);
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
                    enabled: !_emailLocked,
                    footnote: _emailLocked
                        ? 'You signed in with $_emailLockedBy, so your email can\'t be changed.'
                        : null,
                    suffix: _emailLocked
                        ? Padding(
                            padding: EdgeInsets.only(right: 12.w),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: 16.sp,
                              color: ui.textSecondary,
                            ),
                          )
                        : GestureDetector(
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
                    hintText: 'Add your phone number',
                    dialCode: _countryCode,
                    // Changed only through the OTP flow (`change_phone`).
                    readOnly: true,
                    suffix: GestureDetector(
                      onTap: _saving ? null : _onChangePhone,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: AppText(
                          _phoneController.text.trim().isEmpty
                              ? 'Add'
                              : 'Change',
                          color: ui.brandPrimary,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                      ),
                    ),
                    validator: (v) => (v?.trim() ?? '').isEmpty
                        ? 'Phone number is required'
                        : null,
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
    this.textInputAction,
    this.validator,
    this.readOnly = false,
    this.enabled = true,
    this.dialCode,
    this.suffix,
    this.footnote,
  });

  final AppUiColors ui;
  final String label;
  final TextEditingController controller;
  final String hintText;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  /// When true the field is shown but cannot be edited (e.g. email).
  final bool readOnly;

  /// When false the field is fully disabled: not focusable or selectable.
  final bool enabled;

  /// Fixed dial code shown before the input, visible even when empty.
  final String? dialCode;

  /// Optional trailing widget inside the field (e.g. the email "Change" action).
  final Widget? suffix;

  /// Optional note shown under the field (e.g. why it can't be edited).
  final String? footnote;

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
          textInputAction: textInputAction,
          validator: validator,
          maxLines: 1,
          readOnly: readOnly,
          enabled: enabled,
          enableInteractiveSelection: !readOnly && enabled,
          style: TextStyle(
            color: readOnly || !enabled ? ui.textSecondary : ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
            fontFamily: AppFonts.lexend,
          ),
          cursorColor: ui.brandPrimary,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly || !enabled
                ? ui.inputFill.withValues(alpha: 0.5)
                : ui.inputFill,
            isDense: true,
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            prefixIcon: dialCode == null ? null : dialCodePrefix(ui, dialCode!),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.hintColor,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight400,
              fontFamily: AppFonts.lexend,
            ),
            contentPadding: EdgeInsets.fromLTRB(
              dialCode == null ? 14.w : 8.w,
              12.h,
              14.w,
              12.h,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ui.inputBorder),
            ),
            disabledBorder: OutlineInputBorder(
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
        if (footnote != null) ...[
          6.verticalSpace,
          AppText(
            footnote!,
            color: ui.textSecondary,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight400,
          ),
        ],
      ],
    );
  }
}
