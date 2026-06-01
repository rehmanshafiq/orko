import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/features/charging/presentation/models/review_model.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_review_card_widget.dart';

class ChargingStationReviewsWidget extends StatelessWidget {
  const ChargingStationReviewsWidget({
    super.key,
    required this.reviews,
  });

  final List<ReviewModel> reviews;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108.h,
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reviews.length,
        separatorBuilder: (_, __) => 12.horizontalSpace,
        itemBuilder: (context, index) =>
            ChargingStationReviewCardWidget(review: reviews[index]),
      ),
    );
  }
}
