import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/features/profile/domain/entities/profile_entity.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/stats_grid.dart';

/// Body of the "Profile" main tab: the charging-stats grid (plus sections that
/// are currently disabled but kept for future use).
class ProfileTabBody extends StatelessWidget {
  const ProfileTabBody({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StatsGrid(),
        14.verticalSpace,
        // const HistorySection(),
        // const AchievementsCard(),
        // 14.verticalSpace,
        // PersonalInfoCard(profile: profile),
        // 14.verticalSpace,
        // const DrivingEfficiencyCard(),
      ],
    );
  }
}
