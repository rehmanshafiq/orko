import 'package:flutter_test/flutter_test.dart';
import 'package:orko_hubco/features/booking/data/models/live_session_model.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_state.dart';

void main() {
  group('LiveSessionModel booking parsing', () {
    test('parses the nested booking object', () {
      final model = LiveSessionModel.fromJson({
        'active': true,
        'time_left': '45m',
        'booking': {
          'start_time': '13:00:00',
          'end_time': '16:00:00',
          'booking_date': '2026-07-16',
        },
      });

      expect(model.bookingDate, '2026-07-16');
      expect(model.bookingStartTime, '13:00:00');
      expect(model.bookingEndTime, '16:00:00');
      expect(model.timeLeft, '45m');
      expect(
        model.bookingStartDateTime,
        DateTime(2026, 7, 16, 13),
      );
      expect(
        model.bookingEndDateTime,
        DateTime(2026, 7, 16, 16),
      );
      expect(model.bookingSlotDuration, const Duration(hours: 3));
    });

    test('missing or malformed booking never throws', () {
      final noBooking = LiveSessionModel.fromJson({'active': true});
      expect(noBooking.bookingEndDateTime, isNull);
      expect(noBooking.bookingTimeRemaining(DateTime(2026)), isNull);

      final malformed = LiveSessionModel.fromJson({
        'active': true,
        'booking': {'start_time': 'oops', 'end_time': null},
      });
      expect(malformed.bookingEndDateTime, isNull);
    });

    test('slot crossing midnight rolls end to the next day', () {
      final model = LiveSessionModel.fromJson({
        'active': true,
        'booking': {
          'start_time': '23:00:00',
          'end_time': '01:00:00',
          'booking_date': '2026-07-16',
        },
      });
      expect(model.bookingEndDateTime, DateTime(2026, 7, 17, 1));
      expect(model.bookingSlotDuration, const Duration(hours: 2));
    });
  });

  group('booking time remaining', () {
    final model = LiveSessionModel.fromJson({
      'active': true,
      'booking': {
        'start_time': '13:00:00',
        'end_time': '16:00:00',
        'booking_date': '2026-07-16',
      },
    });

    test('counts down to the slot end mid-slot', () {
      expect(
        model.bookingTimeRemaining(DateTime(2026, 7, 16, 13, 14, 47)),
        const Duration(hours: 2, minutes: 45, seconds: 13),
      );
    });

    test('ticks down to the slot end when the session starts early', () {
      // Session goes live at 12:00, an hour before the 13:00 booked start.
      // The countdown must reflect the real time left to the slot end (4h) and
      // keep ticking — it must NOT freeze at the full 3h slot length.
      expect(
        model.bookingTimeRemaining(DateTime(2026, 7, 16, 12)),
        const Duration(hours: 4),
      );
      expect(
        model.bookingTimeRemaining(DateTime(2026, 7, 16, 12, 0, 1)),
        const Duration(hours: 3, minutes: 59, seconds: 59),
      );
    });

    test('bottoms out at zero after the slot ends', () {
      expect(
        model.bookingTimeRemaining(DateTime(2026, 7, 16, 17)),
        Duration.zero,
      );
    });
  });

  group('ChargingStatusState booking countdown', () {
    final session = LiveSessionModel.fromJson({
      'active': true,
      'booking': {
        'start_time': '13:00:00',
        'end_time': '16:00:00',
        'booking_date': '2026-07-16',
      },
    });

    test('formats the live HH:MM:SS label from state.now', () {
      final state = ChargingStatusState(
        status: ChargingStatusViewStatus.success,
        session: session,
        now: DateTime(2026, 7, 16, 13, 14, 47),
      );
      expect(state.hasBookingCountdown, isTrue);
      expect(state.bookingTimeLeftLabel, '02:45:13');
      expect(state.isBookingSlotOver, isFalse);
    });

    test('reports the slot as over at zero remaining', () {
      final state = ChargingStatusState(
        status: ChargingStatusViewStatus.success,
        session: session,
        now: DateTime(2026, 7, 16, 16, 0, 1),
      );
      expect(state.bookingTimeLeftLabel, '00:00:00');
      expect(state.isBookingSlotOver, isTrue);
    });

    test('shows no countdown without a booking', () {
      final state = ChargingStatusState(
        status: ChargingStatusViewStatus.success,
        session: LiveSessionModel.fromJson({'active': true}),
        now: DateTime(2026, 7, 16, 13),
      );
      expect(state.hasBookingCountdown, isFalse);
      expect(state.bookingTimeLeftLabel, '');
    });
  });
}
