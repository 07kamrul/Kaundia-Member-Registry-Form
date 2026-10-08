import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/utils/download_utils.dart';
import '../../data/roadmap_repository.dart';
import '../../domain/roadmap_entities.dart';

part 'roadmap_event.dart';
part 'roadmap_state.dart';

class RoadmapBloc extends Bloc<RoadmapEvent, RoadmapState> {
  RoadmapBloc({RoadmapRepository? repository})
      : _repository =
            repository ?? RoadmapRepository(apiClient: sl<ApiClient>()),
        super(const RoadmapState()) {
    on<RoadmapLoadRequested>(_onLoad);
    on<RoadmapFilterChanged>(
        (e, emit) => emit(state.copyWith(filter: e.filter)));
    on<RoadmapPdfDownloadRequested>(_onDownloadPdf);
    on<RoadmapPdfSavedPathCleared>(
      (_, emit) => emit(state.copyWith(clearPdfSavedPath: true)),
    );
  }

  final RoadmapRepository _repository;

  Future<void> _onLoad(
    RoadmapLoadRequested e,
    Emitter<RoadmapState> emit,
  ) async {
    emit(state.copyWith(status: RoadmapPageStatus.loading, clearError: true));
    try {
      final roadmap = await _repository.getRoadmap();
      emit(state.copyWith(
          status: RoadmapPageStatus.loaded,
          roadmap: roadmap,
          clearError: true));
    } on ApiException {
      emit(state.copyWith(status: RoadmapPageStatus.failure, error: true));
    }
  }

  Future<void> _onDownloadPdf(
    RoadmapPdfDownloadRequested e,
    Emitter<RoadmapState> emit,
  ) async {
    if (state.pdfDownloading) return;
    emit(state.copyWith(
        pdfDownloading: true, clearExportError: true, clearPdfSavedPath: true));
    try {
      final bytes = await _repository.downloadPdf();
      final file = await saveDownload(bytes, 'roadmap.pdf');
      emit(state.copyWith(pdfDownloading: false, pdfSavedPath: file.path));
    } on ApiException {
      emit(state.copyWith(pdfDownloading: false, exportError: true));
    }
  }
}
