import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/features/charging/domain/entities/station_reviews_entity.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/station_reviews_cubit.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/station_reviews_state.dart';
import 'package:orko_hubco/features/charging/presentation/models/review_model.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_review_card_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_section_title_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/station_review_editor_sheet.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/station_reviews_summary_widget.dart';

/// The full "Reviews" section on the station detail screen. Owns the header
/// action (Add / Edit / Delete), the rating summary, and the reviews list,
/// driven by [StationReviewsCubit]. Guests are prompted to authenticate before
/// writing, and every add/update/delete outcome surfaces a snackbar.
class StationReviewsSectionWidget extends StatelessWidget {
  const StationReviewsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return BlocConsumer<StationReviewsCubit, StationReviewsState>(
      listenWhen: (previous, current) =>
          previous.actionEventId != current.actionEventId &&
          current.actionMessage.isNotEmpty,
      listener: (context, state) {
        AppHelpers.showSnackBar(
          context,
          state.actionMessage,
          isError: state.actionIsError,
        );
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(state: state),
            8.verticalSpace,
            _Body(state: state, ui: ui),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final StationReviewsState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: ChargingStationSectionTitleWidget(title: 'Reviews'),
        ),
        if (state.submitting)
          SizedBox(
            height: 16.r,
            width: 16.r,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppUiColors.of(context).brandPrimary,
            ),
          )
        else if (state.hasCurrentUserReview)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionText(
                label: 'Edit',
                color: AppUiColors.of(context).brandPrimary,
                onTap: () => _onEdit(context, state),
              ),
              12.horizontalSpace,
              _ActionText(
                label: 'Delete',
                color: AppColors.removeColor,
                onTap: () => _onDelete(context),
              ),
            ],
          )
        else
          _ActionText(
            label: 'Add Review',
            color: AppUiColors.of(context).brandPrimary,
            icon: Icons.add_rounded,
            onTap: () => _onAdd(context, state),
          ),
      ],
    );
  }

  Future<void> _onAdd(BuildContext context, StationReviewsState state) async {
    if (_promptIfGuest(context)) return;
    final cubit = context.read<StationReviewsCubit>();
    final draft = await StationReviewEditorSheet.show(context);
    if (draft == null) return;
    await cubit.submitReview(
      rating: draft.rating,
      description: draft.description,
    );
  }

  Future<void> _onEdit(BuildContext context, StationReviewsState state) async {
    if (_promptIfGuest(context)) return;
    final existing = state.currentUserReview;
    if (existing == null) return;
    final cubit = context.read<StationReviewsCubit>();
    final draft = await StationReviewEditorSheet.show(
      context,
      initialRating: existing.rating,
      initialDescription: existing.description,
      isEditing: true,
    );
    if (draft == null) return;
    await cubit.submitReview(
      rating: draft.rating,
      description: draft.description,
    );
  }

  Future<void> _onDelete(BuildContext context) async {
    if (_promptIfGuest(context)) return;
    final cubit = context.read<StationReviewsCubit>();
    final confirmed = await _confirmDelete(context);
    if (confirmed != true) return;
    await cubit.deleteMyReview();
  }

  /// Returns true (and shows the auth prompt) when the user is a guest.
  bool _promptIfGuest(BuildContext context) {
    if (!AppStorage.isGuest) return false;
    AuthRequiredDialog.show(
      context,
      message: 'Please log in or create an account to review this station.',
    );
    return true;
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    final ui = AppUiColors.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.cardBackground,
        title: AppText(
          'Delete review?',
          color: ui.textPrimary,
          fontSize: FontSizes.font16Sp,
          fontWeight: FontWeights.weight700,
        ),
        content: AppText(
          'This will permanently remove your review for this station.',
          color: ui.textSecondary,
          fontSize: FontSizes.font13Sp,
          fontWeight: FontWeights.weight400,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: AppText(
              'Cancel',
              color: ui.textSecondary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight600,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: AppText(
              'Delete',
              color: AppColors.removeColor,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.ui});

  final StationReviewsState state;
  final AppUiColors ui;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Center(
          child: SizedBox(
            height: 22.r,
            width: 22.r,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ui.brandPrimary,
            ),
          ),
        ),
      );
    }

    if (state.isGuestGated) {
      return Row(
        children: [
          Expanded(
            child: AppText(
              'Log in to view and write reviews for this station.',
              color: ui.textSecondary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight500,
            ),
          ),
          8.horizontalSpace,
          _ActionText(
            label: 'Login',
            color: ui.brandPrimary,
            onTap: () => AuthRequiredDialog.show(
              context,
              message:
                  'Please log in or create an account to view and write reviews.',
            ),
          ),
        ],
      );
    }

    if (state.isFailure) {
      return Row(
        children: [
          Expanded(
            child: AppText(
              state.errorMessage.isNotEmpty
                  ? state.errorMessage
                  : 'Could not load reviews',
              color: ui.textSecondary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight500,
            ),
          ),
          8.horizontalSpace,
          _ActionText(
            label: 'Retry',
            color: ui.brandPrimary,
            onTap: () => context.read<StationReviewsCubit>().load(),
          ),
        ],
      );
    }

    if (state.reviews.isEmpty) {
      return AppText(
        'No reviews yet. Be the first to review this station.',
        color: ui.textSecondary,
        fontSize: FontSizes.font12Sp,
        fontWeight: FontWeights.weight400,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StationReviewsSummaryWidget(
          averageRating: state.averageRating,
          totalCount: state.totalCount,
        ),
        22.verticalSpace,
        _ReviewsList(reviews: state.reviews),
      ],
    );
  }
}

/// Horizontal list of review cards. Maps the domain review entities onto the
/// existing [ChargingStationReviewCardWidget]'s [ReviewModel].
class _ReviewsList extends StatelessWidget {
  const _ReviewsList({required this.reviews});

  final List<StationReviewItemEntity> reviews;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reviews.length,
        separatorBuilder: (_, __) => 12.horizontalSpace,
        itemBuilder: (context, index) {
          final r = reviews[index];
          return ChargingStationReviewCardWidget(
            review: ReviewModel(
              name: r.customerName,
              text: r.description,
              rating: r.rating.toDouble(),
              createdAt: r.createdAt,
              profilePicture: r.customerProfilePicture,
              isCurrentUser: r.isCurrentUser,
            ),
          );
        },
      ),
    );
  }
}

class _ActionText extends StatelessWidget {
  const _ActionText({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16.r, color: color),
            2.horizontalSpace,
          ],
          AppText(
            label,
            color: color,
            fontSize: FontSizes.font13Sp,
            fontWeight: FontWeights.weight600,
          ),
        ],
      ),
    );
  }
}
