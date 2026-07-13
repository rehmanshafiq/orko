import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// A single question/answer entry rendered in the FAQ accordion.
class _Faq {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;
}

/// The frequently-asked questions shown on the FAQs screen.
const List<_Faq> _faqs = [
  _Faq(
    'How do I start a charging session?',
    'Open the HGL app, scan the QR code on the charger or select it from the '
        'map, choose your connector, and tap Start. You can monitor progress '
        'and stop the session anytime from the app.',
  ),
  _Faq(
    'Which vehicles are compatible with HUBCO Green chargers?',
    'HUBCO Green chargers support all EVs using standard CCS2, Type 2 (AC) and '
        'GB/T connectors. Check your vehicle\'s connector type against the one '
        'listed at each station before charging.',
  ),
  _Faq(
    'How much does charging cost?',
    'Pricing is shown per kWh on each charger\'s details before you start. Your '
        'final cost depends on the energy delivered and is itemised in the app '
        'once the session ends.',
  ),
  _Faq(
    'Do I need the HGL app to charge?',
    'Yes. The HGL app is required to authenticate, start and pay for a charging '
        'session at HUBCO Green chargers.',
  ),
  _Faq(
    'How do I find the nearest station?',
    'Open the map on the home screen to see nearby stations, or use the filters '
        'to find available chargers by connector type and status.',
  ),
  _Faq(
    'Can I reserve a charging slot in advance?',
    'Yes. Select a station and use Pre-book to reserve a slot ahead of time, '
        'subject to availability at that location.',
  ),
  _Faq(
    'How can I host a HUBCO Green charger at my site?',
    'Reach out to our team through Admin Support with your site details, and '
        'we\'ll guide you through the hosting and installation process.',
  ),
  _Faq(
    'Who do I contact for support?',
    'Use the Admin Support option to get in touch with the ORKO team for any '
        'account, billing or charging issues.',
  ),
];

/// Full-screen FAQ list: each question is a collapsible card.
class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

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
          'FAQs',
          color: ui.textPrimary,
          fontSize: FontSizes.font18Sp,
          fontWeight: FontWeights.weight700,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppUtils.horizontal16Padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              16.verticalSpace,
              for (var i = 0; i < _faqs.length; i++) ...[
                if (i > 0) 10.verticalSpace,
                _FaqTile(faq: _faqs[i], initiallyExpanded: i == 0),
              ],
              24.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}

/// Expandable FAQ card. Collapsed it shows just the question with a down
/// chevron; expanded it reveals the answer and the chevron turns green/up.
class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.faq, this.initiallyExpanded = false});

  final _Faq faq;
  final bool initiallyExpanded;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: ui.vehicleImagePlaceholder,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Material(
        color: AppColors.transparentColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppText(
                        widget.faq.question,
                        color: ui.textPrimary,
                        fontSize: FontSizes.font16Sp,
                        fontWeight: FontWeights.weight700,
                      ),
                    ),
                    8.horizontalSpace,
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _expanded ? ui.brandPrimary : ui.textSecondary,
                      size: 24.r,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  10.verticalSpace,
                  AppText(
                    widget.faq.answer,
                    color: ui.textSecondary,
                    fontSize: FontSizes.font13Sp,
                    fontWeight: FontWeights.weight400,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
