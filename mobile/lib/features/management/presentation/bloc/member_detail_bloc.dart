import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

part 'member_detail_event.dart';
part 'member_detail_state.dart';

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
