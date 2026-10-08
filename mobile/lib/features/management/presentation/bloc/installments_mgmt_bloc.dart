import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

part 'installments_mgmt_event.dart';
part 'installments_mgmt_state.dart';

// ----- Installments management (member picker + month cards) -----

// Sentinel used by copyWith to distinguish 'not passed' from 'set to null'.
// ignore: unused_element
T _same<T>() => throw UnsupportedError('sentinel');

class InstallmentsMgmtBloc
    extends Bloc<InstallmentsMgmtEvent, InstallmentsMgmtState> {
  InstallmentsMgmtBloc({required AdminRepository repository})
      : _repository = repository,
        super(const InstallmentsMgmtState()) {
    on<InstallmentsMembersLoadRequested>(_onMembersLoadRequested);
    on<InstallmentsMemberSelected>(
        (e, emit) => _selectMember(e.memberId, emit));
    on<InstallmentMarkPaid>(_onMarkPaid);
  }

  final AdminRepository _repository;

  Member? get selectedMember {
    final id = state.selectedMemberId;
    if (id == null) return null;
    for (final m in state.members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> _onMembersLoadRequested(
    InstallmentsMembersLoadRequested event,
    Emitter<InstallmentsMgmtState> emit,
  ) async {
    emit(state.copyWith(loadingMembers: true, error: () => null));
    try {
      final members = (await _repository.listMembers())
          .where((m) => m.status.name == 'approved')
          .toList();
      emit(state.copyWith(members: members, loadingMembers: false));
      if (members.isNotEmpty) {
        await _selectMember(members.first.id, emit);
      }
    } catch (e) {
      emit(state.copyWith(loadingMembers: false, error: () => e));
    }
  }

  Future<void> _selectMember(
    String memberId,
    Emitter<InstallmentsMgmtState> emit,
  ) async {
    emit(state.copyWith(
      selectedMemberId: () => memberId,
      loadingInstallments: true,
      installments: const [],
      error: () => null,
    ));
    try {
      final installments = await _repository.getMemberInstallments(memberId);
      emit(state.copyWith(
          installments: installments, loadingInstallments: false));
    } catch (e) {
      emit(state.copyWith(loadingInstallments: false, error: () => e));
    }
  }

  Future<void> _onMarkPaid(
    InstallmentMarkPaid event,
    Emitter<InstallmentsMgmtState> emit,
  ) async {
    final installment = event.installment;
    emit(state.copyWith(markingId: () => installment.id, error: () => null));
    try {
      final updated =
          await _repository.updateInstallment(installment.id, 'paid');
      final installments = [
        for (final i in state.installments)
          if (i.id == updated.id) updated else i,
      ];
      emit(state.copyWith(markingId: () => null, installments: installments));
    } catch (e) {
      emit(state.copyWith(markingId: () => null, error: () => e));
    }
  }
}
