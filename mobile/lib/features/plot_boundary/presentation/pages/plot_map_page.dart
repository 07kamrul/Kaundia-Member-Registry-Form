import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injector.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/external_link_launcher.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/geo.dart';
import '../../domain/land_entities.dart';
import '../../domain/phone_links.dart';
import '../../domain/plot_boundary_entities.dart';
import '../../domain/plot_boundary_failure.dart';
import '../bloc/land_map_bloc.dart';
import '../bloc/my_boundaries_cubit.dart';
import '../bloc/my_location_cubit.dart';
import '../bloc/plot_map_bloc.dart';
import '../widgets/draw_panel_sheet.dart';
import '../widgets/land_info_sheet.dart';
import '../widgets/map/boundary_polygon_layer.dart';
import '../widgets/map/plot_map_canvas.dart';
import '../widgets/map/plot_map_overlays.dart';
import '../widgets/owner_bottom_sheet.dart';
import '../widgets/report_sheet.dart';

export '../widgets/report_sheet.dart' show ReportSubmitter;

/// Permission that unlocks drawing boundaries (Angular `boundary.draw_own`).
const String kDrawBoundaryPermission = 'boundary.draw_own';

/// Delay between the last camera event and the viewport dispatch.
const Duration _cameraSettleDelay = Duration(milliseconds: 200);

/// Zoom used when centring on the member's own position.
const double _myLocationZoom = 17;
const double _fitMaxZoom = 18;
const EdgeInsets _fitPadding = EdgeInsets.all(64);

/// Plot boundary map (জমির সীমানা): member-marked boundaries, the official
/// BDS mouza map and the RAJUK masterplan on one full-bleed map, with owner
/// lookup, dag search and entry to the boundary editor.
class PlotMapPage extends StatelessWidget {
  const PlotMapPage({
    super.key,
    this.createBloc,
    this.createLandBloc,
    this.createLocationCubit,
    this.createDrawCubit,
    this.launcher = const UrlLauncherExternalLinkLauncher(),
    this.report,
    this.canDraw,
    this.tileProvider,
  });

  /// Test seams; each defaults to the live implementation.
  final PlotMapBloc Function()? createBloc;
  final LandMapBloc Function()? createLandBloc;
  final MyLocationCubit Function()? createLocationCubit;
  final MyBoundariesCubit Function()? createDrawCubit;
  final ExternalLinkLauncher launcher;

  /// Report-a-problem use case (defaults to the live repository).
  final Future<void> Function(String boundaryId, String note)? report;

  /// Overrides the session permission check (tests).
  final bool? canDraw;

  /// Overrides the network tile provider (tests).
  final TileProvider? tileProvider;

  static const pageRoute = '/plot-map';

  @override
  Widget build(BuildContext context) {
    final society = SocietyBbox.tryParse(AppConfig.societyBboxRaw);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => createBloc?.call() ?? PlotMapBloc()),
        BlocProvider(create: (_) => createLandBloc?.call() ?? LandMapBloc()),
        BlocProvider(
          create: (_) =>
              createLocationCubit?.call() ?? MyLocationCubit(society: society),
        ),
      ],
      child: _PlotMapView(
        society: society,
        launcher: launcher,
        report: report,
        canDraw: canDraw,
        createDrawCubit: createDrawCubit,
        tileProvider: tileProvider,
      ),
    );
  }
}

class _PlotMapView extends StatefulWidget {
  const _PlotMapView({
    required this.society,
    required this.launcher,
    this.report,
    this.canDraw,
    this.createDrawCubit,
    this.tileProvider,
  });

  final TileProvider? tileProvider;
  final SocietyBbox? society;
  final ExternalLinkLauncher launcher;
  final Future<void> Function(String boundaryId, String note)? report;
  final bool? canDraw;
  final MyBoundariesCubit Function()? createDrawCubit;

  @override
  State<_PlotMapView> createState() => _PlotMapViewState();
}

class _PlotMapViewState extends State<_PlotMapView> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _reported = ValueNotifier<Set<String>>(const {});
  Timer? _cameraTimer;
  SocietyBbox? _viewport;
  String _boundaryQuery = '';

  @override
  void initState() {
    super.initState();
    _viewport = widget.society;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final plot = context.read<PlotMapBloc>();
      final viewport = _viewport;
      if (viewport != null && plot.state.bbox == null) {
        plot.add(PlotMapMoved(viewport));
        context.read<LandMapBloc>().add(LandViewportChanged(viewport));
      } else {
        plot.add(const PlotMapRefreshRequested());
      }
    });
  }

  @override
  void dispose() {
    _cameraTimer?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    _reported.dispose();
    super.dispose();
  }

  bool get _canDraw {
    final override = widget.canDraw;
    if (override != null) return override;
    if (!sl.isRegistered<SessionManager>()) return true;
    return sl<SessionManager>().session?.can(kDrawBoundaryPermission) ?? false;
  }

  // ---- Camera ---------------------------------------------------------

  void _onCameraChanged(MapCamera camera) {
    final b = camera.visibleBounds;
    _viewport = SocietyBbox(
      minLng: b.west,
      minLat: b.south,
      maxLng: b.east,
      maxLat: b.north,
    );
    _cameraTimer?.cancel();
    _cameraTimer = Timer(_cameraSettleDelay, _dispatchViewport);
  }

  void _dispatchViewport() {
    final viewport = _viewport;
    if (!mounted || viewport == null) return;
    final land = context.read<LandMapBloc>();
    land.add(LandViewportChanged(viewport));
    if (land.state.mode == MapMode.boundaries) {
      context.read<PlotMapBloc>().add(PlotMapMoved(viewport));
    }
  }

  void _fitTo(SocietyBbox box) {
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(
        LatLng(box.minLat, box.minLng),
        LatLng(box.maxLat, box.maxLng),
      ),
      padding: _fitPadding,
      maxZoom: _fitMaxZoom,
    ));
  }

  // ---- Toolbar actions ------------------------------------------------

  void _selectMode(MapMode mode) {
    final land = context.read<LandMapBloc>();
    if (mode == land.state.mode) return;
    final plot = context.read<PlotMapBloc>();
    _clearSearch();
    final viewport = _viewport;
    if (viewport != null) land.add(LandViewportChanged(viewport));
    land.add(LandModeChanged(mode));
    if (mode == MapMode.boundaries && viewport != null) {
      plot.add(PlotMapMoved(viewport));
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _boundaryQuery = '');
    context.read<PlotMapBloc>().add(const PlotMapSearchRequested(''));
    context.read<LandMapBloc>().add(const LandSearchCleared());
  }

  void _onSearchChanged(String text) {
    if (context.read<LandMapBloc>().state.mode == MapMode.boundaries) {
      setState(() => _boundaryQuery = text);
      context.read<PlotMapBloc>().add(PlotMapSearchRequested(text));
    } else if (text.trim().isEmpty) {
      context.read<LandMapBloc>().add(const LandSearchCleared());
    }
  }

  void _onSearchSubmitted(String text) {
    if (context.read<LandMapBloc>().state.mode != MapMode.boundaries) {
      context.read<LandMapBloc>().add(LandDagSearched(text));
    }
  }

  Future<void> _openDrawPanel() async {
    final result = await showDrawPanelSheet(
      context,
      createCubit: widget.createDrawCubit,
    );
    if (!mounted || result == null) return;
    final extra = switch (result) {
      DrawNewBoundary(:final propertyId) => propertyId,
      EditBoundary(:final boundary) => boundary,
    };
    await context.push('${PlotMapPage.pageRoute}/draw', extra: extra);
    if (mounted) {
      context.read<PlotMapBloc>().add(const PlotMapRefreshRequested());
    }
  }

  // ---- Map taps -------------------------------------------------------

  void _onMapTap(LatLng point) {
    final land = context.read<LandMapBloc>().state;
    final plotBloc = context.read<PlotMapBloc>();
    final layer = land.mode.landLayer;
    if (layer == null) {
      final hit = _boundaryAt(point, plotBloc.state.features);
      plotBloc.add(PlotMapBoundarySelected(hit?.boundaryId));
      return;
    }
    final plot = land.collection?.plotAt(point);
    if (plot == null) return;
    showLandInfoSheet(
      context,
      layer: layer,
      plot: plot,
      launcher: widget.launcher,
    );
  }

  /// Top-most visible boundary under [point] (later features draw on top).
  BoundaryFeature? _boundaryAt(LatLng point, List<BoundaryFeature>? features) {
    for (final f in (features ?? const <BoundaryFeature>[]).reversed) {
      if (BoundaryPolygonLayer.matches(f, _boundaryQuery) &&
          f.points.length >= 3 &&
          pointInRing(point, f.points)) {
        return f;
      }
    }
    return null;
  }

  // ---- Build ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PlotMapBloc, PlotMapState>(
          listenWhen: (a, b) =>
              a.selectedBoundaryId != b.selectedBoundaryId &&
              b.selectedBoundaryId != null,
          listener: (_, state) => _showOwnerSheet(state),
        ),
        BlocListener<PlotMapBloc, PlotMapState>(
          listenWhen: (a, b) =>
              a.highlightedBoundaryId != b.highlightedBoundaryId &&
              b.highlightedBoundaryId != null,
          listener: (_, state) {
            final match = (state.features ?? const <BoundaryFeature>[])
                .where((f) => f.boundaryId == state.highlightedBoundaryId);
            if (match.isEmpty) return;
            final box = SocietyBbox.around(match.first.points);
            if (box != null) _fitTo(box.padded(0.5));
          },
        ),
        BlocListener<LandMapBloc, LandMapState>(
          listenWhen: (a, b) => a.fitSerial != b.fitSerial,
          listener: (_, state) {
            final box = SocietyBbox.around(state.fitPoints);
            if (box != null) _fitTo(box.padded(0.25));
          },
        ),
        BlocListener<MyLocationCubit, MyLocationState>(
          listenWhen: (a, b) => a.status != b.status,
          listener: (_, state) {
            final point = state.point;
            if (state.status == MyLocationStatus.located && point != null) {
              _mapController.move(point, _myLocationZoom);
            } else if (state.status == MyLocationStatus.outsideSociety) {
              final society = widget.society;
              if (society != null) _fitTo(society);
            }
          },
        ),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: _buildCanvas()),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PlotMapProgress(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: PlotMapTopOverlay(
                        searchController: _searchController,
                        canDraw: _canDraw,
                        onSearchChanged: _onSearchChanged,
                        onSearchSubmitted: _onSearchSubmitted,
                        onSearchCleared: _clearSearch,
                        onLocate: () =>
                            context.read<MyLocationCubit>().locate(),
                        onDraw: _openDrawPanel,
                        onModeChanged: _selectMode,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: SafeArea(
                top: false,
                child: BlocBuilder<PlotMapBloc, PlotMapState>(
                  buildWhen: (a, b) => a.layer != b.layer,
                  builder: (context, state) => PlotMapBottomOverlay(
                    basemap: state.layer,
                    onToggleBasemap: () =>
                        context.read<PlotMapBloc>().add(PlotMapLayerChanged(
                              state.layer == MapLayer.street
                                  ? MapLayer.satellite
                                  : MapLayer.street,
                            )),
                    onRetryBoundaries: () => context
                        .read<PlotMapBloc>()
                        .add(const PlotMapRefreshRequested()),
                    onRetryLand: () => context
                        .read<LandMapBloc>()
                        .add(const LandRetryRequested()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return BlocBuilder<PlotMapBloc, PlotMapState>(
      buildWhen: (a, b) =>
          !identical(a.features, b.features) ||
          a.layer != b.layer ||
          a.highlightedBoundaryId != b.highlightedBoundaryId,
      builder: (context, plot) => BlocBuilder<LandMapBloc, LandMapState>(
        buildWhen: (a, b) =>
            a.mode != b.mode ||
            !identical(a.collection, b.collection) ||
            a.highlightDag != b.highlightDag,
        builder: (context, land) =>
            BlocBuilder<MyLocationCubit, MyLocationState>(
          buildWhen: (a, b) => a.point != b.point,
          builder: (context, location) => PlotMapCanvas(
            controller: _mapController,
            mode: land.mode,
            basemap: plot.layer,
            society: widget.society,
            features: plot.features ?? const [],
            boundaryQuery: _boundaryQuery,
            highlightedBoundaryId: plot.highlightedBoundaryId,
            landCollection: land.collection,
            highlightDag: land.highlightDag,
            myLocation: location.point,
            onTap: _onMapTap,
            onCameraChanged: _onCameraChanged,
            tileProvider: widget.tileProvider,
          ),
        ),
      ),
    );
  }

  // ---- Owner sheet ----------------------------------------------------

  void _showOwnerSheet(PlotMapState state) {
    final bloc = context.read<PlotMapBloc>();
    final boundaryId = state.selectedBoundaryId!;
    bloc.add(PlotMapOwnerRequested(boundaryId));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return BlocBuilder<PlotMapBloc, PlotMapState>(
          bloc: bloc,
          builder: (sheetCtx, s) {
            final loc = AppLocalizations.of(sheetCtx);
            final failureMessage = switch (s.ownerFailureKind) {
              PlotBoundaryFailureKind.rateLimited => loc.plotMapOwnerRateLimited,
              PlotBoundaryFailureKind.notApproved => loc.plotMapOwnerNotApproved,
              PlotBoundaryFailureKind.network => loc.commonNetworkError,
              _ => loc.plotMapOwnerLoadError,
            };
            return ValueListenableBuilder<Set<String>>(
              valueListenable: _reported,
              builder: (_, reported, __) => BoundaryOwnerSheet(
                status: s.ownerStatus,
                owner: s.owner,
                failure: failureMessage,
                feature: s.selectedFeature,
                reported: reported.contains(boundaryId),
                onRetry: () => bloc.add(PlotMapOwnerRequested(boundaryId)),
                onCall: () => _openContact(sheetCtx, telUri(s.owner?.mobile)),
                onWhatsApp: () =>
                    _openContact(sheetCtx, whatsAppUri(s.owner?.mobile)),
                onReport: () => showReportSheet(
                  sheetCtx,
                  boundaryId: boundaryId,
                  submit: ReportSubmitter(widget.report),
                  onSent: () =>
                      _reported.value = {..._reported.value, boundaryId},
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted) bloc.add(const PlotMapBoundarySelected(null));
    });
  }

  Future<void> _openContact(BuildContext sheetCtx, Uri? uri) async {
    final loc = AppLocalizations.of(sheetCtx);
    final opened = uri != null && await widget.launcher.open(uri);
    if (!opened && sheetCtx.mounted) {
      showAppToast(sheetCtx, loc.plotMapOwnerLoadError, error: true);
    }
  }
}
