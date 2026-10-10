import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/plot_boundary_repository_impl.dart';
import '../../domain/plot_boundary_entities.dart';
import '../../domain/plot_boundary_failure.dart';
import '../../domain/plot_boundary_repository.dart';

enum MyBoundariesStatus { loading, ready, failure }

class MyBoundariesState extends Equatable {
  const MyBoundariesState({
    this.status = MyBoundariesStatus.loading,
    this.properties = const [],
    this.boundaries = const [],
    this.selectedPropertyId,
    this.withdrawingId,
    this.withdrawFailed = false,
    this.failureKind,
  });

  final MyBoundariesStatus status;
  final List<OwnProperty> properties;
  final List<PlotBoundary> boundaries;
  final String? selectedPropertyId;

  /// Boundary whose pending submission is being withdrawn.
  final String? withdrawingId;
  final bool withdrawFailed;
  final PlotBoundaryFailureKind? failureKind;

  /// Own plots that have no boundary yet — the only valid draw targets.
  List<OwnProperty> get availableProperties {
    final claimed = {for (final b in boundaries) b.propertyId};
    return [
      for (final p in properties)
        if (!claimed.contains(p.propertyId)) p,
    ];
  }

  MyBoundariesState copyWith({
    MyBoundariesStatus? status,
    List<OwnProperty>? properties,
    List<PlotBoundary>? boundaries,
    String? selectedPropertyId,
    bool clearSelectedProperty = false,
    String? withdrawingId,
    bool clearWithdrawing = false,
    bool? withdrawFailed,
    PlotBoundaryFailureKind? failureKind,
  }) {
    return MyBoundariesState(
      status: status ?? this.status,
      properties: properties ?? this.properties,
      boundaries: boundaries ?? this.boundaries,
      selectedPropertyId: clearSelectedProperty
          ? null
          : (selectedPropertyId ?? this.selectedPropertyId),
      withdrawingId:
          clearWithdrawing ? null : (withdrawingId ?? this.withdrawingId),
      withdrawFailed: withdrawFailed ?? this.withdrawFailed,
      failureKind: failureKind ?? this.failureKind,
    );
  }

  @override
  List<Object?> get props => [
        status,
        properties,
        boundaries,
        selectedPropertyId,
        withdrawingId,
        withdrawFailed,
        failureKind,
      ];
}

/// "Draw boundary" panel: pick one of the member's plots without a boundary,
/// and manage own boundaries (status timeline, withdraw a pending review).
class MyBoundariesCubit extends Cubit<MyBoundariesState> {
  MyBoundariesCubit({
    GetMyProperties? getMyProperties,
    GetMyBoundaries? getMyBoundaries,
    WithdrawBoundary? withdrawBoundary,
  })  : _injectedProperties = getMyProperties,
        _injectedBoundaries = getMyBoundaries,
        _injectedWithdraw = withdrawBoundary,
        super(const MyBoundariesState());

  final GetMyProperties? _injectedProperties;
  final GetMyBoundaries? _injectedBoundaries;
  final WithdrawBoundary? _injectedWithdraw;

  late final PlotBoundaryRepositoryImpl _liveRepository =
      PlotBoundaryRepositoryImpl(apiClient: sl<ApiClient>());
  late final GetMyProperties _getMyProperties =
      _injectedProperties ?? GetMyProperties(_liveRepository);
  late final GetMyBoundaries _getMyBoundaries =
      _injectedBoundaries ?? GetMyBoundaries(_liveRepository);
  late final WithdrawBoundary _withdraw =
      _injectedWithdraw ?? WithdrawBoundary(_liveRepository);

  Future<void> load() async {
    emit(state.copyWith(status: MyBoundariesStatus.loading));
    try {
      final results =
          await Future.wait([_getMyProperties(), _getMyBoundaries()]);
      final next = state.copyWith(
        status: MyBoundariesStatus.ready,
        properties: results[0] as List<OwnProperty>,
        boundaries: results[1] as List<PlotBoundary>,
      );
      final stillValid = next.availableProperties
          .any((p) => p.propertyId == state.selectedPropertyId);
      emit(stillValid ? next : next.copyWith(clearSelectedProperty: true));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: MyBoundariesStatus.failure,
        failureKind: plotBoundaryFailureKindOf(e),
      ));
    } on FormatException {
      emit(state.copyWith(
        status: MyBoundariesStatus.failure,
        failureKind: PlotBoundaryFailureKind.other,
      ));
    }
  }

  void selectProperty(String propertyId) =>
      emit(state.copyWith(selectedPropertyId: propertyId));

  /// Withdraws the pending submission of [boundaryId]; the live (approved)
  /// shape is untouched. Reloads the list on success.
  Future<void> withdraw(String boundaryId) async {
    if (state.withdrawingId != null) return;
    emit(state.copyWith(withdrawingId: boundaryId, withdrawFailed: false));
    try {
      await _withdraw(boundaryId);
      emit(state.copyWith(clearWithdrawing: true));
      await load();
    } on ApiException {
      emit(state.copyWith(clearWithdrawing: true, withdrawFailed: true));
    }
  }
}
