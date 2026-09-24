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

/// A titled group of FAQs (e.g. "Getting Started").
class _FaqSection {
  const _FaqSection(this.title, this.faqs);

  final String title;
  final List<_Faq> faqs;
}

/// The frequently-asked questions shown on the FAQs screen.
const List<_FaqSection> _sections = [
  _FaqSection('Getting Started', [
    _Faq(
      'Can I use the HUBCO Green App without creating an account?',
      'Users can browse charging station locations and availability without an '
          'account. However, booking a charging session and accessing charging '
          'history require registration.',
    ),
    _Faq(
      'What features does the HUBCO Green App offer?',
      'The HUBCO Green App brings everything you need for a seamless EV charging '
          'experience in one place:\n'
          '• Locate charging stations with real-time availability\n'
          '• Book charging sessions\n'
          '• Monitor charging progress\n'
          '• View charging history and receipts\n'
          '• Make secure in-app payments\n'
          '• Plan long-distance trips with optimized charging stops',
    ),
    _Faq(
      'I forgot my password. How can I reset it?',
      'Select Forgot Password on the login screen and follow the verification '
          'process.',
    ),
    _Faq(
      'How do I update my vehicle details?',
      'Go to My Account > My Vehicles, select the vehicle, and update the '
          'required information.',
    ),
    _Faq(
      'Is there an option to add multiple vehicles?',
      'Yes. Users can add multiple vehicles to their account, provided these are '
          "compatible with HUBCO Green's CCS2 chargers.",
    ),
    _Faq(
      'What should I do if the app crashes or freezes?',
      'Restart the application and ensure you are using the latest version. If '
          'the issue persists, contact HUBCO Green Customer Support.',
    ),
  ]),
  _FaqSection('Finding a Charger', [
    _Faq(
      'How do I find a charging station?',
      'Use the Map to locate nearby HUBCO Green charging stations. You can search '
          'by location, browse available chargers, and view station details.',
    ),
    _Faq(
      'Can I check charger availability before I arrive?',
      'Yes. The app provides real-time charger availability to help you plan '
          'charging.',
    ),
  ]),
  _FaqSection('Planning a Trip', [
    _Faq(
      'Can I plan a trip using the HUBCO Green App?',
      'Yes. The Trip Planning feature helps you identify charging stations along '
          'your route and allows you to pre-book charging slots.',
    ),
    _Faq(
      'How does Trip Planning work?',
      'The Trip Planning feature calculates your route and recommends suitable '
          'HUBCO Green charging stations based on your destination and the '
          'charging network.',
    ),
  ]),
  _FaqSection('Booking a Charging Session', [
    _Faq(
      'How do I book a charging slot?',
      'Register on the HUBCO Green App, add your vehicle, choose a charging '
          'station, select an available charger and time slot, and confirm your '
          'booking.\n\n'
          'Bookings can be made up to 24 hours in advance and modified up to 1 '
          'hour before the scheduled session.\n\n'
          'Walk-in charging is also available, subject to charger availability.',
    ),
    _Faq(
      'Is booking mandatory?',
      'Booking is recommended but not mandatory. Booking in advance helps ensure '
          'a charger is available at your preferred time. If a charger is '
          'available when you arrive at the station, you can simply start your '
          'charging session without a prior booking.',
    ),
    _Faq(
      'What happens if I arrive late for my booking?',
      'Your booking will be held for 10 minutes from the booking time. After '
          'that, it will be released and any subsequent charging will be treated '
          'as a walk-in.',
    ),
    _Faq(
      'What happens if all chargers are occupied?',
      'The app displays real-time availability. You may wait or select another '
          'nearby charging station.',
    ),
  ]),
  _FaqSection('At the Charging Station', [
    _Faq(
      'How do I get to my booked charging station?',
      'Simply tap Start Journey to navigate to the station. Upon arrival, the '
          'station operator will verify your booking ID and vehicle registration '
          'number and initiate your charging session.',
    ),
    _Faq(
      'How can I monitor my charging status?',
      'You can monitor your charging session in real time through the HUBCO '
          "Green App, even when you're away from your vehicle. Once charging is "
          "complete, you'll receive a notification through the app.",
    ),
    _Faq(
      'Can I leave my vehicle while charging?',
      'Yes. You can monitor the charging session remotely through the app. '
          'Please return once charging is complete.',
    ),
    _Faq(
      'What charging information can I see during the session?',
      '• Charging status\n'
          '• Estimated time remaining\n'
          '• Session duration\n'
          '• Energy delivered (kWh)',
    ),
    _Faq(
      'How long does DC fast charging take?',
      'Charging time depends on the charger rating, vehicle and battery '
          'condition. Most EVs charge from 20% to 80% in approximately 30–45 '
          'minutes.',
    ),
  ]),
  _FaqSection('Payments & Receipts', [
    _Faq(
      'What payment methods are accepted?',
      'All HUBCO Green charging stations support multiple payment options for '
          'your convenience. You can pay securely through the HUBCO Green App '
          'using online payment or make your payment at the charging station '
          'using a POS terminal or cash.',
    ),
    _Faq(
      'Can I save my preferred payment method?',
      'Yes. You can save and manage your preferred payment method for a faster '
          'checkout experience.\n\n'
          'Payment information is used only to process transactions, issue '
          'receipts, manage refunds or billing queries, and meet financial record '
          "requirements. HUBCO Green does not store customers' bank account "
          'information.',
    ),
    _Faq(
      'Will I receive a receipt for my charging session?',
      'Yes. Once payment is completed, a digital receipt is automatically '
          'generated and saved in the History section of the app. You can access '
          'and download your receipt anytime for your records.',
    ),
    _Faq(
      'How can I request a refund?',
      'You can submit your query through the HUBCO Green App or contact our '
          'Customer Support team via our official email address or helpline. Our '
          'team will review your request and guide you through the next steps.\n\n'
          'Please note that refunds cannot be processed directly at the charging '
          'station.',
    ),
    _Faq(
      'Will walk-in charging appear in my history?',
      'Yes. At HUBCO Green charging stations, our operators are encouraged to '
          'record the vehicle details of all walk-in charging sessions in the '
          'system. If you are a registered HUBCO Green App user, your walk-in '
          'charging session will appear in the History section of the app, even '
          'if you did not book a charging slot in advance. This allows you to '
          'conveniently track your past charging sessions and access or download '
          'your receipts.',
    ),
  ]),
  _FaqSection('Safety', [
    _Faq(
      'Can I charge my NEV in rain?',
      'Yes. HUBCO Green charging stations are designed to operate safely in a '
          'variety of weather conditions, including rain. However, in the event '
          'of extreme weather or if conditions pose a safety risk, charging '
          'services may be temporarily suspended. In such cases, please contact '
          'HUBCO Green Customer Support.',
    ),
  ]),
  _FaqSection('Customer Support', [
    _Faq(
      'How can I report an issue or provide feedback?',
      'Contact HUBCO Green Customer Support via the app, email, station manager '
          'or helpline. HUBCO Green team will be happy to assist you.',
    ),
  ]),
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
              for (var s = 0; s < _sections.length; s++) ...[
                (s == 0 ? 16 : 24).verticalSpace,
                AppText(
                  _sections[s].title,
                  color: ui.textSecondary,
                  fontSize: FontSizes.font15Sp,
                  fontWeight: FontWeights.weight700,
                ),
                10.verticalSpace,
                for (var i = 0; i < _sections[s].faqs.length; i++) ...[
                  if (i > 0) 10.verticalSpace,
                  _FaqTile(
                    faq: _sections[s].faqs[i],
                    initiallyExpanded: s == 0 && i == 0,
                  ),
                ],
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
