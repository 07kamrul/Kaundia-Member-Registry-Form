import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/admin_repository.dart';
import '../../../domain/admin_entities.dart';

// ----- Installments management (member picker + month cards) -----

class InstallmentsMgmtState extends Equatable {
  const InstallmentsMgmtState({
    this.members = const [],
    this.loadingMembers = true,
    this.selectedMemberId,
    this.installments = const [],
    this.loadingInstallments = false,
    this.markingId,
    this.error,
  });

  final List<Member> members;
  final bool loadingMembers;
  final String? selectedMemberId;
  final List<Installment> installments;
  final bool loadingInstallments;

  /// Installment currently being marked paid.
  final String? markingId;
  final Object? error;

  InstallmentsMgmtState copyWith({
    List<Member>? members,
    bool? loadingMembers,
    String? Function() selectedMemberId = _same,
    List<Installment>? installments,
    bool? loadingInstallments,
    String? Function() markingId = _same,
    Object? Function() error = _same,
  }) =>
      InstallmentsMgmtState(
        members: members ?? this.members,
        loadingMembers: loadingMembers ?? this.loadingMembers,
        selectedMemberId: selectedMemberId == _same ? this.selectedMemberId : selectedMemberId(),
        installments: installments ?? this.installments,
        loadingInstallments: loadingInstallments ?? this.loadingInstallments,
        markingId: markingId == _same ? this.markingId : markingId(),
        error: error == _same ? this.error : error(),
      );

  static T _same<T>() => throw UnsupportedError('sentinel');

  @override
  List<Object?> get props => [
        members,
        loadingMembers,
        selectedMemberId,
        installments,
        loadingInstallments,
        markingId,
        error,
      ];
}

class InstallmentsMgmtCubit extends Cubit<InstallmentsMgmtState> {
  InstallmentsMgmtCubit({required AdminRepository repository})
      : _repository = repository,
        super(const InstallmentsMgmtState());

  final AdminRepository _repository;

  Member? get selectedMember {
    final id = state.selectedMemberId;
    if (id == null) return null;
    for (final m in state.members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> loadMembers() async {
    emit(state.copyWith(loadingMembers: true, error: () => null));
    try {
      final members =
          (await _repository.listMembers()).where((m) => m.status.name == 'approved').toList();
      emit(state.copyWith(members: members, loadingMembers: false));
      if (members.isNotEmpty) {
        await selectMember(members.first.id);
      }
    } catch (e) {
      emit(state.copyWith(loadingMembers: false, error: () => e));
    }
  }

  Future<void> selectMember(String memberId) async {
    emit(state.copyWith(
      selectedMemberId: () => memberId,
      loadingInstallments: true,
      installments: const [],
      error: () => null,
    ));
    try {
      final installments = await _repository.getMemberInstallments(memberId);
      emit(state.copyWith(installments: installments, loadingInstallments: false));
    } catch (e) {
      emit(state.copyWith(loadingInstallments: false, error: () => e));
    }
  }

  Future<void> markPaid(Installment installment) async {
    emit(state.copyWith(markingId: () => installment.id, error: () => null));
    try {
      final updated = await _repository.updateInstallment(installment.id, 'paid');
      final installments = [
        for (final i in state.installments) if (i.id == updated.id) updated else i,
      ];
      emit(state.copyWith(markingId: () => null, installments: installments));
    } catch (e) {
      emit(state.copyWith(markingId: () => null, error: () => e));
    }
  }
}

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
    Object? Function() error = _same,
  }) =>
      PicnicPaymentsState(
        memberFilter: memberFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
        items: items,
        totalCollected: totalCollected,
        count: count,
        loading: loading ?? this.loading,
        error: error == _same ? this.error : error(),
      );

  static T _same<T>() => throw UnsupportedError('sentinel');

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

class PicnicPaymentsCubit extends Cubit<PicnicPaymentsState> {
  PicnicPaymentsCubit({required AdminRepository repository})
      : _repository = repository,
        super(const PicnicPaymentsState(loading: true));

  final AdminRepository _repository;

  Future<void> load() async {
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

  void setMemberFilter(String? raw) {
    emit(PicnicPaymentsState(
      memberFilter: raw == null || raw.isEmpty ? null : int.tryParse(raw),
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
    ));
    load();
  }

  void setDateRange({String? from, String? to}) {
    emit(PicnicPaymentsState(
      memberFilter: state.memberFilter,
      dateFrom: from ?? state.dateFrom,
      dateTo: to ?? state.dateTo,
    ));
  }

  void resetFilters() {
    emit(const PicnicPaymentsState());
    load();
  }
}
