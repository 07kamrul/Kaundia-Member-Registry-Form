import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/enums/enums.dart';
import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

part 'submissions_event.dart';
part 'submissions_state.dart';

class SubmissionsBloc extends Bloc<SubmissionsEvent, SubmissionsState> {
  SubmissionsBloc({required AdminRepository repository})
      : _repository = repository,
        super(const SubmissionsData(
            filter: SubmissionStatus.pending, loading: true)) {
    on<SubmissionsLoadRequested>((event, emit) => _load(emit));
    on<SubmissionsFilterChanged>((event, emit) async {
      emit(_d.copyWith(filter: () => event.filter));
      await _load(emit);
    });
  }

  final AdminRepository _repository;

  /// Re-typed view of the current state (emits go through the base copyWith).
  /// Current state; copyWith returns the base state type, so never
  /// downcast here (that would silently reset to defaults).
  SubmissionsState get _d => state;

  Future<void> _load(Emitter<SubmissionsState> emit) async {
    emit(_d.copyWith(loading: true, error: () => null));
    try {
      final items = await _repository.listSubmissions(status: state.filter);
      emit(_d.copyWith(items: items, loading: false));
    } catch (e) {
      emit(_d.copyWith(loading: false, error: () => e));
    }
  }
}
