part of 'picnic_payments_bloc.dart';

// ----- Picnic payments (filters + summary) -----

class PicnicPaymentsState extends Equatable {
  const PicnicPaymentsState({
    this.memberFilter,
    this.dateFrom = '',
    this.dateTo = '',
    this.items = const [],
    this.totalCollected = 0,
    this.count = 0,
    this.loading = false,
    this.error,
  });

  final int? memberFilter;
  final String dateFrom;
  final String dateTo;
  final List<AdminPicnicPayment> items;
  final num totalCollected;
  final int count;
  final bool loading;
  final Object? error;

  PicnicPaymentsState copyWith({
    bool? loading,
    Object? Function()? error,
  }) =>
      PicnicPaymentsState(
        memberFilter: memberFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
        items: items,
        totalCollected: totalCollected,
        count: count,
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
      );

  @override
  List<Object?> get props => [
        memberFilter,
        dateFrom,
        dateTo,
        items,
        totalCollected,
        count,
        loading,
        error,
      ];
}
