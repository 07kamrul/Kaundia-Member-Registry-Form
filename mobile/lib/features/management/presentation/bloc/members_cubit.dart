import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/admin_repository.dart';
import '../../../domain/admin_entities.dart';

// ----- Members list -----

class MembersState extends Equatable {
  const MembersState({this.items = const [], this.loading = false, this.error, this.busyId});

  final List<Member> items;
  final bool loading;
  final Object? error;

  /// Member currently being mutated (delete/reset password).
  final String? busyId;

  MembersState copyWith({
    List<Member>? items,
    bool? loading,
    Object? Function() error = _same,
    String? Function() busyId = _same,
  }) =>
      MembersState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error == _same ? this.error : error(),
        busyId: busyId == _same ? this.busyId : busyId(),
      );

  static T _same<T>() => throw UnsupportedError('sentinel');

  @override
  List<Object?> get props => [items, loading, error, busyId];
}

class MembersCubit extends Cubit<MembersState> {
  MembersCubit({required AdminRepository repository})
      : _repository = repository,
        super(const MembersState());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final items = await _repository.listMembers();
      emit(state.copyWith(items: items, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: () => e));
    }
  }

  /// Returns true on success.
  Future<bool> delete(String memberId) async {
    emit(state.copyWith(busyId: () => memberId, error: () => null));
    try {
      await _repository.deleteMember(memberId);
      emit(state.copyWith(
        busyId: () => null,
        items: state.items.where((m) => m.id != memberId).toList(growable: false),
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(busyId: () => null, error: () => e));
      return false;
    }
  }

  /// Returns true when the reset email was sent.
  Future<bool> resetPassword(String memberId) async {
    emit(state.copyWith(busyId: () => memberId, error: () => null));
    try {
      final sent = await _repository.resetMemberPassword(memberId);
      emit(state.copyWith(busyId: () => null));
      return sent;
    } catch (e) {
      emit(state.copyWith(busyId: () => null, error: () => e));
      return false;
    }
  }
}

// ----- Member detail (read-only profile) -----

class MemberDetailState extends Equatable {
  const MemberDetailState({this.loading = true, this.profile, this.error});

  final bool loading;
  final MemberProfile? profile;
  final Object? error;

  @override
  List<Object?> get props => [loading, profile, error];
}

class MemberDetailCubit extends Cubit<MemberDetailState> {
  MemberDetailCubit({required AdminRepository repository, required String id})
      : _repository = repository,
        _id = id,
        super(const MemberDetailState());

  final AdminRepository _repository;
  final String _id;

  Future<void> load() async {
    emit(MemberDetailState(loading: true));
    try {
      final profile = await _repository.getMemberProfile(_id);
      emit(MemberDetailState(loading: false, profile: profile));
    } catch (e) {
      emit(MemberDetailState(loading: false, error: e));
    }
  }
}
