part of 'picnic_payment_bloc.dart';

sealed class PicnicPaymentEvent extends Equatable {
  const PicnicPaymentEvent();
  @override
  List<Object?> get props => const [];
}

final class PicnicStarted extends PicnicPaymentEvent {
  const PicnicStarted();
}

final class PicnicHistoryRefreshRequested extends PicnicPaymentEvent {
  const PicnicHistoryRefreshRequested();
}

final class PicnicRatesRefreshRequested extends PicnicPaymentEvent {
  const PicnicRatesRefreshRequested();
}

final class PicnicDateChanged extends PicnicPaymentEvent {
  const PicnicDateChanged(this.date);
  final String date;
  @override
  List<Object?> get props => [date];
}

final class PicnicHeadsChanged extends PicnicPaymentEvent {
  const PicnicHeadsChanged(this.count);
  final int count;
  @override
  List<Object?> get props => [count];
}

final class PicnicLabelNameChanged extends PicnicPaymentEvent {
  const PicnicLabelNameChanged(this.index, this.name);
  final int index;
  final String name;
  @override
  List<Object?> get props => [index, name];
}

final class PicnicLabelRelationChanged extends PicnicPaymentEvent {
  const PicnicLabelRelationChanged(this.index, this.relation);
  final int index;
  final PicnicRelation relation;
  @override
  List<Object?> get props => [index, relation];
}

final class PicnicReceiptNoChanged extends PicnicPaymentEvent {
  const PicnicReceiptNoChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

final class PicnicPaymentMethodChanged extends PicnicPaymentEvent {
  const PicnicPaymentMethodChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

final class PicnicSubmitted extends PicnicPaymentEvent {
  const PicnicSubmitted();
}
