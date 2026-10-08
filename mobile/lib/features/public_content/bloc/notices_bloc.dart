import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/content_repository.dart';
import '../domain/content_entities.dart';

part 'notices_event.dart';
part 'notices_state.dart';

class NoticesBloc extends Bloc<NoticesEvent, NoticesState> {
  NoticesBloc({ContentRepository? repository})
      : _repo = repository ?? ContentRepository(apiClient: sl<ApiClient>()),
        super(const NoticesInitial()) {
    on<NoticesRequested>(_onRequested);
  }

  final ContentRepository _repo;

  Future<void> _onRequested(NoticesRequested e, Emitter<NoticesState> emit) async {
    emit(const NoticesLoading());
    try {
      final notices = await _repo.listNotices();
      emit(NoticesLoaded(notices: notices));
    } on ApiException catch (err) {
      emit(NoticesFailure(error: err));
    }
  }
}
