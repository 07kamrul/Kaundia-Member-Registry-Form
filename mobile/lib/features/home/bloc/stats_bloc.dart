import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../dashboard/data/public_stats_repository.dart';
import '../../dashboard/domain/entity/public_stats.dart';

part 'stats_event.dart';
part 'stats_state.dart';

/// Landing stats: on error the card falls back to zeros (Angular behaviour).
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  StatsBloc({PublicStatsRepository? repository})
      : _repo = repository ?? sl<PublicStatsRepository>(),
        super(const StatsInitial()) {
    on<StatsLoadRequested>(_onLoad);
  }

  final PublicStatsRepository _repo;

  Future<void> _onLoad(StatsLoadRequested e, Emitter<StatsState> emit) async {
    emit(const StatsLoading());
    try {
      final stats = await _repo.getStats();
      emit(StatsLoaded(stats: stats));
    } catch (_) {
      emit(const StatsFailure());
    }
  }
}
