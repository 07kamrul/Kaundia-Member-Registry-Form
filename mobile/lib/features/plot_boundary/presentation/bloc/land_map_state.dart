part of 'land_map_bloc.dart';

enum LandLoadStatus { idle, loading, loaded, failure }

class LandMapState extends Equatable {
  const LandMapState({
    this.mode = MapMode.boundaries,
    this.status = LandLoadStatus.idle,
    this.collection,
    this.viewport,
    this.cache = const {},
    this.cacheBounds = const {},
    this.highlightDag,
    this.dagNotFound = false,
    this.fitPoints = const [],
    this.fitSerial = 0,
  });

  final MapMode mode;
  final LandLoadStatus status;

  /// Plots to draw for the active official layer (null in boundaries mode).
  final LandCollection? collection;
  final SocietyBbox? viewport;

  /// Last response per layer plus the (padded) bounds it covers, so a
  /// viewport inside those bounds re-renders without a request.
  final Map<LandLayer, LandCollection> cache;
  final Map<LandLayer, SocietyBbox> cacheBounds;

  /// Normalised dag number whose polygons stay highlighted.
  final String? highlightDag;
  final bool dagNotFound;

  /// One-shot camera request: the page fits these points when [fitSerial]
  /// changes.
  final List<LatLng> fitPoints;
  final int fitSerial;

  bool get isLoading => status == LandLoadStatus.loading;
  bool get hasError => status == LandLoadStatus.failure;
  bool get isTruncated => collection?.truncated ?? false;

  LandMapState copyWith({
    MapMode? mode,
    LandLoadStatus? status,
    LandCollection? collection,
    bool clearCollection = false,
    SocietyBbox? viewport,
    Map<LandLayer, LandCollection>? cache,
    Map<LandLayer, SocietyBbox>? cacheBounds,
    String? highlightDag,
    bool clearHighlight = false,
    bool? dagNotFound,
    List<LatLng>? fitPoints,
    int? fitSerial,
  }) {
    return LandMapState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      collection: clearCollection ? null : (collection ?? this.collection),
      viewport: viewport ?? this.viewport,
      cache: cache ?? this.cache,
      cacheBounds: cacheBounds ?? this.cacheBounds,
      highlightDag: clearHighlight ? null : (highlightDag ?? this.highlightDag),
      dagNotFound: dagNotFound ?? this.dagNotFound,
      fitPoints: fitPoints ?? this.fitPoints,
      fitSerial: fitSerial ?? this.fitSerial,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        status,
        collection,
        viewport,
        cache,
        cacheBounds,
        highlightDag,
        dagNotFound,
        fitPoints,
        fitSerial,
      ];
}
