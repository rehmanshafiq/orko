import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_confirmation_state.dart';

class BookingConfirmationCubit extends Cubit<BookingConfirmationState> {
  BookingConfirmationCubit({int amountPaid = 472})
      : super(BookingConfirmationState(amountPaid: amountPaid));
}
