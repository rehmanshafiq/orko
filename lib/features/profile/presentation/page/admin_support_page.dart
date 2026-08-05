import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/support/domain/entities/support_category_entity.dart';
import 'package:orko_hubco/features/support/presentation/cubit/support_ticket_cubit.dart';
import 'package:orko_hubco/features/support/presentation/cubit/support_ticket_state.dart';

/// Max attachments and per-file constraints enforced client-side (mirrors the
/// backend: up to 5 files, jpg/jpeg/png, each < 2MB).
const int _maxAttachments = 5;
const int _maxFileBytes = 2 * 1024 * 1024;
const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png'};

/// Admin Support screen: lets the user raise a complaint / technical issue by
/// picking a category, describing the problem and optionally attaching images.
/// Categories are fetched from the backend on open; the ticket is submitted via
/// `POST api/v1/cvp/cvp-support-ticket/`.
class AdminSupportPage extends StatelessWidget {
  const AdminSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SupportTicketCubit>()..loadCategories(),
      child: const _AdminSupportView(),
    );
  }
}

class _AdminSupportView extends StatefulWidget {
  const _AdminSupportView();

  @override
  State<_AdminSupportView> createState() => _AdminSupportViewState();
}

class _AdminSupportViewState extends State<_AdminSupportView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _detailsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  SupportCategoryEntity? _category;
  final List<String> _attachmentPaths = [];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  /// Lets the user pick images, then keeps only valid jpg/jpeg/png files under
  /// 2MB, capping the total at [_maxAttachments]. Rejected files are surfaced.
  Future<void> _pickAttachments() async {
    final remaining = _maxAttachments - _attachmentPaths.length;
    if (remaining <= 0) {
      _toast('You can attach up to $_maxAttachments images.');
      return;
    }

    List<XFile> picked;
    try {
      picked = await _picker.pickMultiImage(imageQuality: 85);
    } catch (_) {
      _toast('Could not open the gallery.');
      return;
    }
    if (picked.isEmpty || !mounted) return;

    final accepted = <String>[];
    var rejectedType = 0;
    var rejectedSize = 0;
    var rejectedOverflow = 0;

    for (final file in picked) {
      if (accepted.length >= remaining) {
        rejectedOverflow++;
        continue;
      }
      final ext = file.path.contains('.')
          ? file.path.split('.').last.toLowerCase()
          : '';
      if (!_allowedExtensions.contains(ext)) {
        rejectedType++;
        continue;
      }
      int size;
      try {
        size = await File(file.path).length();
      } catch (_) {
        size = _maxFileBytes + 1; // treat unreadable as too large
      }
      if (size > _maxFileBytes) {
        rejectedSize++;
        continue;
      }
      accepted.add(file.path);
    }

    if (!mounted) return;
    if (accepted.isNotEmpty) {
      setState(() => _attachmentPaths.addAll(accepted));
    }

    final notes = <String>[
      if (rejectedType > 0) '$rejectedType not JPG/PNG',
      if (rejectedSize > 0) '$rejectedSize over 2MB',
      if (rejectedOverflow > 0) '$rejectedOverflow over the limit',
    ];
    if (notes.isNotEmpty) {
      _toast('Some files were skipped: ${notes.join(', ')}.');
    }
  }

  void _removeAttachment(String path) {
    setState(() => _attachmentPaths.remove(path));
  }

  void _submit() {
    // A ticket is tied to the authenticated user — guests must sign in first.
    if (AppStorage.isGuest) {
      AuthRequiredDialog.show(
        context,
        feature: 'support',
        message:
            'You\'re browsing as a guest. Please log in or create an account to contact support.',
      );
      return;
    }
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || _category == null) return;

    FocusScope.of(context).unfocus();
    context.read<SupportTicketCubit>().submit(
          categoryValue: _category!.value,
          description: _detailsController.text.trim(),
          attachmentPaths: List<String>.from(_attachmentPaths),
        );
  }

  void _toast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

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
          'Admin Support',
          color: ui.textPrimary,
          fontSize: FontSizes.font18Sp,
          fontWeight: FontWeights.weight700,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: BlocConsumer<SupportTicketCubit, SupportTicketState>(
          listenWhen: (p, c) => p.status != c.status,
          listener: (context, state) {
            if (state.status == SupportTicketStatus.success) {
              final ref = state.ticket?.referenceCode ?? '';
              _toast(
                ref.isEmpty
                    ? 'Your request has been submitted. Our team will get back to you.'
                    : 'Request submitted. Reference: $ref',
              );
              Navigator.of(context).maybePop();
            } else if (state.status == SupportTicketStatus.failure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.error ?? 'Failed to submit your request'),
                    backgroundColor: AppColors.removeColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
            }
          },
          builder: (context, state) {
            final submitting = state.isSubmitting;
            // Keep the selection valid if the category list changed underneath.
            final selected =
                state.categories.contains(_category) ? _category : null;
            return SingleChildScrollView(
              padding: AppUtils.horizontal16Padding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    16.verticalSpace,
                    AppText(
                      'Facing a technical issue or need help? Pick a category and '
                      'describe the problem — our team will get back to you.',
                      color: ui.textSecondary,
                      fontSize: FontSizes.font13Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                    20.verticalSpace,
                    _CategoryField(
                      ui: ui,
                      state: state,
                      value: selected,
                      enabled: !submitting,
                      onChanged: (v) => setState(() => _category = v),
                      onRetry: () =>
                          context.read<SupportTicketCubit>().loadCategories(),
                    ),
                    16.verticalSpace,
                    _DetailsField(
                      ui: ui,
                      controller: _detailsController,
                      enabled: !submitting,
                    ),
                    16.verticalSpace,
                    _AttachmentsSection(
                      ui: ui,
                      paths: _attachmentPaths,
                      enabled: !submitting,
                      onAdd: _pickAttachments,
                      onRemove: _removeAttachment,
                    ),
                    24.verticalSpace,
                    PrimaryButtonWidget(
                      text: submitting ? 'Submitting…' : 'Submit',
                      isEnabled: !submitting,
                      onPress: _submit,
                      buttonWidth: double.infinity,
                      buttonHeight: 44.h,
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
            );
          },
        ),
      ),
    );
  }
}

/// The "Category" section: renders a loading box, an error+retry box, or the
/// dropdown once the backend-driven list has loaded.
class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.ui,
    required this.state,
    required this.value,
    required this.onChanged,
    required this.onRetry,
    required this.enabled,
  });

  final AppUiColors ui;
  final SupportTicketState state;
  final SupportCategoryEntity? value;
  final ValueChanged<SupportCategoryEntity?> onChanged;
  final VoidCallback onRetry;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Category',
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
        6.verticalSpace,
        if (state.categoriesLoading)
          _boxed(child: _loadingRow())
        else if (state.categoriesFailed)
          _boxed(child: _errorRow())
        else
          DropdownButtonFormField<SupportCategoryEntity>(
            initialValue: value,
            isExpanded: true,
            menuMaxHeight: 260.h,
            validator: (v) => v == null ? 'Please select a category.' : null,
            onChanged: enabled ? onChanged : null,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled ? ui.textSecondary : ui.textMuted,
              size: 22.r,
            ),
            dropdownColor: ui.cardBackground,
            borderRadius: BorderRadius.circular(12.r),
            style: TextStyle(
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight500,
            ),
            hint: AppText(
              'Select a category',
              color: AppColors.hintColor,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight400,
            ),
            items: [
              for (final c in state.categories)
                DropdownMenuItem<SupportCategoryEntity>(
                  value: c,
                  child: AppText(
                    c.label,
                    color: ui.textPrimary,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            decoration: _fieldDecoration(ui),
          ),
      ],
    );
  }

  Widget _boxed({required Widget child}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: child,
    );
  }

  Widget _loadingRow() {
    return Row(
      children: [
        SizedBox(
          width: 16.r,
          height: 16.r,
          child: CircularProgressIndicator(strokeWidth: 2, color: ui.brandPrimary),
        ),
        10.horizontalSpace,
        AppText(
          'Loading categories…',
          color: ui.textSecondary,
          fontSize: FontSizes.font13Sp,
          fontWeight: FontWeights.weight400,
        ),
      ],
    );
  }

  Widget _errorRow() {
    return Row(
      children: [
        Expanded(
          child: AppText(
            state.categoriesError ?? 'Could not load categories.',
            color: AppColors.redColor,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
            maxLines: 2,
          ),
        ),
        10.horizontalSpace,
        GestureDetector(
          onTap: onRetry,
          behavior: HitTestBehavior.opaque,
          child: AppText(
            'Retry',
            color: ui.brandPrimary,
            fontSize: FontSizes.font13Sp,
            fontWeight: FontWeights.weight700,
          ),
        ),
      ],
    );
  }
}

/// Multi-line details field where the user describes the issue.
class _DetailsField extends StatelessWidget {
  const _DetailsField({
    required this.ui,
    required this.controller,
    required this.enabled,
  });

  final AppUiColors ui;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Details',
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
        6.verticalSpace,
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: 6,
          minLines: 5,
          textCapitalization: TextCapitalization.sentences,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Please describe your issue.'
              : null,
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
          ),
          decoration: _fieldDecoration(
            ui,
            hint: 'Describe your issue in detail…',
          ),
        ),
      ],
    );
  }
}

/// Optional image attachments with add/remove and inline thumbnails.
class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({
    required this.ui,
    required this.paths,
    required this.onAdd,
    required this.onRemove,
    required this.enabled,
  });

  final AppUiColors ui;
  final List<String> paths;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final canAddMore = paths.length < _maxAttachments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Attachments (optional)',
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
        4.verticalSpace,
        AppText(
          'Up to $_maxAttachments images · JPG/PNG · max 2MB each',
          color: ui.textSecondary,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight400,
        ),
        10.verticalSpace,
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: [
            for (final path in paths)
              _AttachmentThumb(
                ui: ui,
                path: path,
                enabled: enabled,
                onRemove: () => onRemove(path),
              ),
            if (canAddMore)
              _AddAttachmentTile(ui: ui, onTap: enabled ? onAdd : null),
          ],
        ),
      ],
    );
  }
}

class _AttachmentThumb extends StatelessWidget {
  const _AttachmentThumb({
    required this.ui,
    required this.path,
    required this.onRemove,
    required this.enabled,
  });

  final AppUiColors ui;
  final String path;
  final VoidCallback onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Image.file(
            File(path),
            width: 72.r,
            height: 72.r,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 72.r,
              height: 72.r,
              color: ui.vehicleImagePlaceholder,
              child: Icon(
                Icons.broken_image_outlined,
                color: ui.textMuted,
                size: 22.r,
              ),
            ),
          ),
        ),
        if (enabled)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.all(2.r),
                decoration: BoxDecoration(
                  color: AppColors.removeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.whiteColor, width: 1.5),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.whiteColor,
                  size: 14.r,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddAttachmentTile extends StatelessWidget {
  const _AddAttachmentTile({required this.ui, required this.onTap});

  final AppUiColors ui;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 72.r,
        height: 72.r,
        decoration: BoxDecoration(
          color: ui.cardBackground,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: ui.borderSubtle),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: onTap == null ? ui.textMuted : ui.brandPrimary,
              size: 24.r,
            ),
            4.verticalSpace,
            AppText(
              'Add',
              color: ui.textSecondary,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight500,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared input decoration matching the app's other form fields.
InputDecoration _fieldDecoration(AppUiColors ui, {String? hint}) {
  return InputDecoration(
    filled: true,
    fillColor: ui.cardBackground,
    isDense: true,
    hintText: hint,
    hintStyle: TextStyle(
      color: AppColors.hintColor,
      fontSize: FontSizes.font14Sp,
      fontWeight: FontWeights.weight400,
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: ui.borderSubtle),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: ui.brandPrimary),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: ui.borderSubtle),
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
  );
}
