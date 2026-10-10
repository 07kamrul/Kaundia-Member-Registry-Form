import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/land_data_repository_impl.dart';
import '../../domain/dag_details_entities.dart';
import '../../domain/dag_number.dart';
import '../../domain/land_data_repository.dart';

const String kBdsSurvey = 'bds';
const int _sheetWidth = 3;
const int _notFound = 404;
const int _tooManyRequests = 429;

enum DagInfoFailureKind { notFound, rateLimited, other }

sealed class DagInfoState extends Equatable {
  const DagInfoState();
  @override
  List<Object?> get props => const [];
}

final class DagInfoLoading extends DagInfoState {
  const DagInfoLoading();
}

final class DagInfoLoaded extends DagInfoState {
  const DagInfoLoaded(this.details);
  final DagDetails details;
  @override
  List<Object?> get props => [details];
}

/// The record exists but lists no khatian.
final class DagInfoEmpty extends DagInfoState {
  const DagInfoEmpty(this.details);
  final DagDetails details;
  @override
  List<Object?> get props => [details];
}

final class DagInfoFailure extends DagInfoState {
  const DagInfoFailure(this.kind);
  final DagInfoFailureKind kind;
  @override
  List<Object?> get props => [kind];
}

/// Lazily loads the khatian record of one tapped dag. Owner names are
/// personal data: held in memory only, never logged or cached.
class DagInfoCubit extends Cubit<DagInfoState> {
  DagInfoCubit({
    required this.sheet,
    required this.dag,
    this.survey = kBdsSurvey,
    LandDataRepository? repository,
  })  : _repository =
            repository ?? LandDataRepositoryImpl(apiClient: sl<ApiClient>()),
        super(const DagInfoLoading());

  final String survey;
  final String sheet;
  final String dag;
  final LandDataRepository _repository;

  /// Sheets are zero-padded to three ASCII digits ("22" -> "022").
  static String normalizeSheet(String raw) =>
      toAsciiDigits(raw.trim()).padLeft(_sheetWidth, '0');

  Future<void> load() async {
    if (sheet.trim().isEmpty || dag.trim().isEmpty) {
      emit(const DagInfoFailure(DagInfoFailureKind.notFound));
      return;
    }
    emit(const DagInfoLoading());
    try {
      final details = await _repository.dagDetails(
        survey,
        normalizeSheet(sheet),
        toAsciiDigits(dag.trim()),
      );
      if (isClosed) return;
      emit(details.khatians.isEmpty
          ? DagInfoEmpty(details)
          : DagInfoLoaded(details));
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(DagInfoFailure(switch (e.statusCode) {
        _notFound => DagInfoFailureKind.notFound,
        _tooManyRequests => DagInfoFailureKind.rateLimited,
        _ => DagInfoFailureKind.other,
      }));
    } on FormatException {
      if (isClosed) return;
      emit(const DagInfoFailure(DagInfoFailureKind.other));
    }
  }

  Future<void> retry() => load();
}
