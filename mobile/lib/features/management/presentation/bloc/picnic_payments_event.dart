part of 'picnic_payments_bloc.dart';

sealed class PicnicPaymentsEvent extends Equatable {
  const PicnicPaymentsEvent();
  @override
  List<Object?> get props => const [];
}

final class PicnicPaymentsLoadRequested extends PicnicPaymentsEvent {
  const PicnicPaymentsLoadRequested();
}

final class PicnicPaymentsMemberFilterChanged extends PicnicPaymentsEvent {
  const PicnicPaymentsMemberFilterChanged({this.raw});

  final String? raw;

  @override
  List<Object?> get props => [raw];
}

final class PicnicPaymentsDateRangeChanged extends PicnicPaymentsEvent {
  const PicnicPaymentsDateRangeChanged({this.from, this.to});

  final String? from;
  final String? to;

  @override
  List<Object?> get props => [from, to];
}

final class PicnicPaymentsFiltersReset extends PicnicPaymentsEvent {
  const PicnicPaymentsFiltersReset();
}
