import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/station_reviews_cubit.dart';

/// The value entered in the review editor sheet.
typedef ReviewDraft = ({int rating, String description});

/// Bottom sheet for writing or editing a review: a 1–5 star picker plus a
/// description field capped at [StationReviewsCubit.maxDescriptionLength].
///
/// Returns the entered [ReviewDraft] when submitted, or null when dismissed.
class StationReviewEditorSheet extends StatefulWidget {
  const StationReviewEditorSheet({
    super.key,
    this.initialRating = 0,
    this.initialDescription = '',
    this.isEditing = false,
  });

  final int initialRating;
  final String initialDescription;
  final bool isEditing;

  static Future<ReviewDraft?> show(
    BuildContext context, {
    int initialRating = 0,
    String initialDescription = '',
    bool isEditing = false,
  }) {
    final ui = AppUiColors.of(context);
    return showModalBottomSheet<ReviewDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ui.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (_) => StationReviewEditorSheet(
        initialRating: initialRating,
        initialDescription: initialDescription,
        isEditing: isEditing,
      ),
    );
  }

  @override
  State<StationReviewEditorSheet> createState() =>
      _StationReviewEditorSheetState();
}

class _StationReviewEditorSheetState extends State<StationReviewEditorSheet> {
  late int _rating = widget.initialRating;
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialDescription);

  static const int _maxLength = StationReviewsCubit.maxDescriptionLength;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit => _rating >= 1 && _controller.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop<ReviewDraft>(
      (rating: _rating, description: _controller.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 12.h,
        // Lift the sheet above the keyboard.
        bottom: 16.h + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            child: Container(
              height: 3.h,
              width: 66.w,
              decoration: BoxDecoration(
                color: ui.textSecondary.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          16.verticalSpace,
          AppText(
            widget.isEditing ? 'Edit your review' : 'Write a review',
            color: ui.textPrimary,
            fontSize: FontSizes.font18Sp,
            fontWeight: FontWeights.weight700,
          ),
          16.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _rating = i),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Icon(
                      i <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 36.r,
                      color: AppColors.ratingStarColor,
                    ),
                  ),
                ),
            ],
          ),
          16.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: ui.innerCardBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: ui.borderSubtle),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            child: TextField(
              controller: _controller,
              maxLength: _maxLength,
              maxLines: 4,
              minLines: 3,
              textInputAction: TextInputAction.newline,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_maxLength),
              ],
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: FontSizes.font14Sp,
              ),
              cursorColor: ui.brandPrimary,
              decoration: InputDecoration(
                border: InputBorder.none,
                counterStyle: TextStyle(
                  color: ui.textSecondary,
                  fontSize: FontSizes.font10Sp,
                ),
                hintText: 'Share your experience at this station…',
                hintStyle: TextStyle(
                  color: ui.textMuted,
                  fontSize: FontSizes.font14Sp,
                ),
              ),
            ),
          ),
          16.verticalSpace,
          PrimaryButtonWidget(
            text: widget.isEditing ? 'Update Review' : 'Submit Review',
            isEnabled: _canSubmit,
            onPress: _submit,
            buttonHeight: 38.h,
            cornerRadius: 24.r,
            gradientColors: const [
              AppColors.primaryDarkColor,
              AppColors.primaryDarkButtonColor,
            ],
          ),
        ],
      ),
    );
  }
}
