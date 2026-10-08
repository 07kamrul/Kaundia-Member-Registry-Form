// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

// ----- Events -----

sealed class MembersEvent extends Equatable {
  const MembersEvent();
  @override
  List<Object?> get props => const [];
}

final class MembersLoadRequested extends MembersEvent {
  const MembersLoadRequested();
}

/// Mutating events carry an optional completer so callers can await the
/// outcome (replaces the cubit's `Future<bool>` returns).
final class MemberDeleted extends MembersEvent {
  const MemberDeleted(this.memberId, {this.completer});
  final String memberId;
  final Completer<bool>? completer;
  @override
  List<Object?> get props => [memberId];
}

final class MemberPasswordResetRequested extends MembersEvent {
  const MemberPasswordResetRequested(this.memberId, {this.completer});
  final String memberId;
  final Completer<bool>? completer;
  @override
  List<Object?> get props => [memberId];
}


// ----- Members list -----

class MembersState extends Equatable {
  const MembersState(
      {this.items = const [], this.loading = false, this.error, this.busyId});

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

class MembersBloc extends Bloc<MembersEvent, MembersState> {
  MembersBloc({required AdminRepository repository})
      : _repository = repository,
        super(const MembersState()) {
    on<MembersLoadRequested>(_onLoad);
    on<MemberDeleted>(_onDelete);
    on<MemberPasswordResetRequested>(_onResetPassword);
  }

  final AdminRepository _repository;

  Future<void> _onLoad(
    MembersLoadRequested e,
    Emitter<MembersState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final items = await _repository.listMembers();
      emit(state.copyWith(items: items, loading: false));
    } catch (err) {
      emit(state.copyWith(loading: false, error: () => err));
    }
  }

  Future<void> _onDelete(
    MemberDeleted e,
    Emitter<MembersState> emit,
  ) async {
    emit(state.copyWith(busyId: () => e.memberId, error: () => null));
    try {
      await _repository.deleteMember(e.memberId);
      emit(state.copyWith(
        busyId: () => null,
        items: state.items
            .where((m) => m.id != e.memberId)
            .toList(growable: false),
      ));
      e.completer?.complete(true);
    } catch (err) {
      emit(state.copyWith(busyId: () => null, error: () => err));
      e.completer?.complete(false);
    }
  }

  Future<void> _onResetPassword(
    MemberPasswordResetRequested e,
    Emitter<MembersState> emit,
  ) async {
    emit(state.copyWith(busyId: () => e.memberId, error: () => null));
    try {
      final sent = await _repository.resetMemberPassword(e.memberId);
      emit(state.copyWith(busyId: () => null));
      e.completer?.complete(sent);
    } catch (err) {
      emit(state.copyWith(busyId: () => null, error: () => err));
      e.completer?.complete(false);
    }
  }
}

// ----- Member detail (read-only profile) -----

// Events

sealed class MemberDetailEvent extends Equatable {
  const MemberDetailEvent();
  @override
  List<Object?> get props => const [];
}

final class MemberDetailLoadRequested extends MemberDetailEvent {
  const MemberDetailLoadRequested();
}

// State

class MemberDetailState extends Equatable {
  const MemberDetailState({this.loading = true, this.profile, this.error});

  final bool loading;
  final MemberProfile? profile;
  final Object? error;

  @override
  List<Object?> get props => [loading, profile, error];
}

class MemberDetailBloc extends Bloc<MemberDetailEvent, MemberDetailState> {
  MemberDetailBloc({required AdminRepository repository, required String id})
      : _repository = repository,
        _id = id,
        super(const MemberDetailState()) {
    on<MemberDetailLoadRequested>(_onLoad);
  }

  final AdminRepository _repository;
  final String _id;

  Future<void> _onLoad(
    MemberDetailLoadRequested e,
    Emitter<MemberDetailState> emit,
  ) async {
    emit(MemberDetailState(loading: true));
    try {
      final profile = await _repository.getMemberProfile(_id);
      emit(MemberDetailState(loading: false, profile: profile));
    } catch (err) {
      emit(MemberDetailState(loading: false, error: err));
    }
  }
}
