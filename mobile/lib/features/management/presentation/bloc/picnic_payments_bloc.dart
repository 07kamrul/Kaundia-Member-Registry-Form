// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

part 'picnic_payments_event.dart';
part 'picnic_payments_state.dart';

class PicnicPaymentsBloc
    extends Bloc<PicnicPaymentsEvent, PicnicPaymentsState> {
  PicnicPaymentsBloc({required AdminRepository repository})
      : _repository = repository,
        super(const PicnicPaymentsState(loading: true)) {
    on<PicnicPaymentsLoadRequested>((e, emit) => _load(emit));
    on<PicnicPaymentsMemberFilterChanged>((e, emit) async {
      final raw = e.raw;
      emit(PicnicPaymentsState(
        memberFilter: raw == null || raw.isEmpty ? null : int.tryParse(raw),
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
      ));
      await _load(emit);
    });
    on<PicnicPaymentsDateRangeChanged>((e, emit) {
      emit(PicnicPaymentsState(
        memberFilter: state.memberFilter,
        dateFrom: e.from ?? state.dateFrom,
        dateTo: e.to ?? state.dateTo,
      ));
    });
    on<PicnicPaymentsFiltersReset>((e, emit) async {
      emit(const PicnicPaymentsState());
      await _load(emit);
    });
  }

  final AdminRepository _repository;

  Future<void> _load(Emitter<PicnicPaymentsState> emit) async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final page = await _repository.getPicnicPayments(
        memberId: state.memberFilter,
        dateFrom: state.dateFrom.isEmpty ? null : state.dateFrom,
        dateTo: state.dateTo.isEmpty ? null : state.dateTo,
      );
      emit(PicnicPaymentsState(
        memberFilter: state.memberFilter,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        items: page.items,
        totalCollected: page.totalCollected,
        count: page.count,
        loading: false,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: () => e));
    }
  }
}
