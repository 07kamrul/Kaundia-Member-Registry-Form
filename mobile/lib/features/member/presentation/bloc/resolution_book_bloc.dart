import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/resolution_book_repository.dart';
import '../../domain/resolution_book_entities.dart';

part 'resolution_book_event.dart';
part 'resolution_book_state.dart';

class ResolutionBookBloc
    extends Bloc<ResolutionBookEvent, ResolutionBookState> {
  ResolutionBookBloc({ResolutionBookRepository? repository})
      : _repository =
            repository ?? ResolutionBookRepository(apiClient: sl<ApiClient>()),
        super(const ResolutionBookState()) {
    on<ResolutionBookLoaded>(_onLoaded);
    on<ResolutionBookFiltersChanged>(_onFiltersChanged);
    on<ResolutionBookFiltersCleared>(_onFiltersCleared);
    on<ResolutionBookPageChanged>(_onPageChanged);
  }

  final ResolutionBookRepository _repository;

  Future<void> _onLoaded(
    ResolutionBookLoaded event,
    Emitter<ResolutionBookState> emit,
  ) async {
    emit(
        state.copyWith(status: ResolutionBookStatus.loading, clearError: true));
    try {
      final summary = await _repository.summary();
      emit(state.copyWith(
          status: ResolutionBookStatus.loaded,
          summary: summary,
          clearError: true));
    } on ApiException {
      emit(state.copyWith(status: ResolutionBookStatus.failure, error: true));
    }
    await _loadMeetings(emit, page: 0);
  }

  Future<void> _onFiltersChanged(
    ResolutionBookFiltersChanged event,
    Emitter<ResolutionBookState> emit,
  ) async {
    emit(state.copyWith(
      query: event.query,
      meetingType: event.meetingType,
      meetingStatus: event.meetingStatus,
      dateFrom: event.dateFrom,
      dateTo: event.dateTo,
      page: 0,
      listLoading: true,
    ));
    await _loadMeetings(emit, page: 0);
  }

  Future<void> _onFiltersCleared(
    ResolutionBookFiltersCleared event,
    Emitter<ResolutionBookState> emit,
  ) async {
    emit(state.copyWith(
      query: '',
      meetingType: '',
      meetingStatus: '',
      dateFrom: '',
      dateTo: '',
      page: 0,
      listLoading: true,
    ));
    await _loadMeetings(emit, page: 0);
  }

  Future<void> _onPageChanged(
    ResolutionBookPageChanged event,
    Emitter<ResolutionBookState> emit,
  ) async {
    final clamped = event.target.clamp(0, state.totalPages - 1);
    emit(state.copyWith(page: clamped, listLoading: true));
    await _loadMeetings(emit, page: clamped);
  }

  Future<void> _loadMeetings(
    Emitter<ResolutionBookState> emit, {
    required int page,
  }) async {
    try {
      final result = await _repository.listMeetings(
        q: state.query.trim().isEmpty ? null : state.query.trim(),
        meetingType: state.meetingType.isEmpty ? null : state.meetingType,
        meetingStatus: state.meetingStatus.isEmpty ? null : state.meetingStatus,
        dateFrom: state.dateFrom.isEmpty ? null : state.dateFrom,
        dateTo: state.dateTo.isEmpty ? null : state.dateTo,
        limit: state.pageSize,
        offset: page * state.pageSize,
      );
      emit(state.copyWith(
        meetings: result.items,
        total: result.total,
        page: page,
        listLoading: false,
        clearError: true,
      ));
    } on ApiException {
      emit(state.copyWith(listLoading: false, error: true));
    }
  }
}
