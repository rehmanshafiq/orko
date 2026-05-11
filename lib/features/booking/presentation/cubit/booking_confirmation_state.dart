import 'package:equatable/equatable.dart';

class BookingConfirmationState extends Equatable {
  const BookingConfirmationState({
    this.amountPaid = 472,
  });

  final int amountPaid;

  @override
  List<Object?> get props => [amountPaid];
}
