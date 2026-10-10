import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/external_link_launcher.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/plot_boundary_repository_impl.dart';
import '../../domain/geo.dart';
import '../../domain/phone_links.dart';
import '../../domain/plot_boundary_failure.dart';
import '../../domain/plot_boundary_repository.dart';
import '../bloc/plot_map_bloc.dart';
import '../widgets/boundary_disclaimer_banner.dart';
import '../widgets/boundary_status_style.dart';
import '../widgets/owner_bottom_sheet.dart';

/// Plot boundary map (জমির সীমানা): approved/disputed polygons for everyone,
/// own polygons of any status, owner lookup, and entry to the editor.
class PlotMapPage extends StatelessWidget {
  const PlotMapPage({
    super.key,
    this.createBloc,
    this.launcher = const UrlLauncherExternalLinkLauncher(),
    this.report,
  });

  /// Test seam; defaults to a bloc wired to the live API.
  final PlotMapBloc Function()? createBloc;
  final ExternalLinkLauncher launcher;

  /// Report-a-problem use case (defaults to the live repository).
  final Future<void> Function(String boundaryId, String note)? report;

  static const pageRoute = '/plot-map';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          createBloc?.call() ?? PlotMapBloc(),
      child: _PlotMapView(launcher: launcher, report: report),
    );
  }
}

class _PlotMapView extends StatefulWidget {
  const _PlotMapView({required this.launcher, this.report});

  final ExternalLinkLauncher launcher;
  final Future<void> Function(String boundaryId, String note)? report;

  @override
  State<_PlotMapView> createState() => _PlotMapViewState();
}

class _PlotMapViewState extends State<_PlotMapView> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  SocietyBbox? _societyBbox;

  @override
  void initState() {
    super.initState();
    final raw = AppConfig.societyBboxRaw;
    if (raw.isNotEmpty) {
      try {
        _societyBbox = SocietyBbox.parse(raw);
      } on FormatException {
        _societyBbox = null;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<PlotMapBloc>();
      if (_societyBbox != null && bloc.state.bbox == null) {
        bloc.add(PlotMapMoved(_societyBbox!));
      } else {
        bloc.add(const PlotMapRefreshRequested());
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  SocietyBbox? _currentBbox() {
    try {
      final b = _mapController.camera.visibleBounds;
      return SocietyBbox(
        minLng: b.west,
        minLat: b.south,
        maxLng: b.east,
        maxLat: b.north,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: loc.boundaryTitle,
            subtitle: loc.boundarySubtitle,
            icon: Icons.map_outlined,
          ),
          const BoundaryDisclaimerBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: loc.boundarySearchDagHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<PlotMapBloc>()
                              .add(const PlotMapSearchRequested(''));
                        },
                      ),
                    ),
                    onSubmitted: (q) => context
                        .read<PlotMapBloc>()
                        .add(PlotMapSearchRequested(q)),
                  ),
                ),
                const SizedBox(width: 8),
                _LayerToggle(),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                BlocConsumer<PlotMapBloc, PlotMapState>(
                  listenWhen: (a, b) =>
                      a.selectedBoundaryId != b.selectedBoundaryId &&
                      b.selectedBoundaryId != null,
                  listener: (context, state) => _showOwnerSheet(state),
                  builder: (context, state) {
                    return FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _societyBbox != null
                            ? LatLng(
                                (_societyBbox!.minLat + _societyBbox!.maxLat) / 2,
                                (_societyBbox!.minLng + _societyBbox!.maxLng) / 2)
                            : const LatLng(23.8103, 90.4125),
                        initialZoom: 15,
                        onTap: (_, __) => context
                            .read<PlotMapBloc>()
                            .add(const PlotMapBoundarySelected(null)),
                        onMapEvent: (_) => _onMove(),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: state.layer == MapLayer.street
                              ? AppConfig.mapTileUrl
                              : AppConfig.satelliteTileUrl,
                          userAgentPackageName: 'bd.kaundia.app',
                        ),
                        if (state.features != null)
                          PolygonLayer(
                            polygons: [
                              for (final f in state.features!)
                                if (f.points.isNotEmpty)
                                  Polygon(
                                    points: f.points,
                                    color: BoundaryStatusStyle.colorsFor(
                                      context,
                                      status: f.status,
                                      isMine: f.isMine,
                                    ).$1,
                                    borderColor: f.boundaryId ==
                                            state.highlightedBoundaryId
                                        ? Theme.of(context).colorScheme.primary
                                        : BoundaryStatusStyle.colorsFor(
                                            context,
                                            status: f.status,
                                            isMine: f.isMine,
                                          ).$2,
                                    borderStrokeWidth:
                                        f.boundaryId == state.highlightedBoundaryId
                                            ? 4
                                            : 2,
                                  ),
                            ],
                          ),
                        RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              state.layer == MapLayer.street
                                  ? 'OpenStreetMap contributors'
                                  : 'Esri World Imagery',
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                // Loading / failure overlays.
                BlocBuilder<PlotMapBloc, PlotMapState>(
                  builder: (context, state) {
                    if (state.status == PlotMapStatus.loading &&
                        (state.features == null || state.features!.isEmpty)) {
                      return const Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (state.status == PlotMapStatus.failure &&
                        state.features == null) {
                      return Align(
                        child: InlineError(
                          message: AppLocalizations.of(context).boundaryLoadError,
                          onRetry: () => context
                              .read<PlotMapBloc>()
                              .add(const PlotMapRefreshRequested()),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // FABs.
                Positioned(
                  right: 12,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'plot_map_locate',
                        tooltip: AppLocalizations.of(context).boundaryMyLocation,
                        onPressed: _goToMyLocation,
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.extended(
                        heroTag: 'plot_map_draw',
                        icon: const Icon(Icons.edit_location_alt_outlined),
                        label: Text(AppLocalizations.of(context).boundaryDraw),
                        onPressed: () async {
                          await context.push('${PlotMapPage.pageRoute}/draw');
                          if (context.mounted) {
                            context
                                .read<PlotMapBloc>()
                                .add(const PlotMapRefreshRequested());
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onMove() {
    final bbox = _currentBbox();
    if (bbox != null) {
      // The bloc debounces before refetching.
      context.read<PlotMapBloc>().add(PlotMapMoved(bbox));
    }
  }

  Future<void> _goToMyLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _mapController.move(LatLng(pos.latitude, pos.longitude), 17);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Location unavailable'))); // tolerated failure
    }
  }

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
            final feature = s.selectedFeature;
            final failureMessage = switch (s.ownerFailureKind) {
              PlotBoundaryFailureKind.rateLimited =>
                AppLocalizations.of(sheetCtx).boundaryErrorRateLimited,
              PlotBoundaryFailureKind.notApproved =>
                AppLocalizations.of(sheetCtx).boundaryErrorNotApproved,
              PlotBoundaryFailureKind.network =>
                AppLocalizations.of(sheetCtx).commonNetworkError,
              _ => AppLocalizations.of(sheetCtx).boundaryOwnerLoadError,
            };
            return BoundaryOwnerSheet(
              status: s.ownerStatus,
              owner: s.owner,
              failure: failureMessage,
              feature: feature,
              onRetry: () => bloc.add(PlotMapOwnerRequested(boundaryId)),
              onCall: () => _openContact(sheetCtx, telUri(s.owner?.mobile)),
              onWhatsApp: () =>
                  _openContact(sheetCtx, whatsAppUri(s.owner?.mobile)),
              onReport: () => _showReportSheet(sheetCtx, bloc, boundaryId),
            );
          },
        );
      },
    ).then((_) {
      bloc.add(const PlotMapBoundarySelected(null));
    });
  }

  Future<void> _openContact(BuildContext sheetCtx, Uri? uri) async {
    final loc = AppLocalizations.of(sheetCtx);
    final opened = uri != null && await widget.launcher.open(uri);
    if (!opened && sheetCtx.mounted) {
      showAppToast(sheetCtx, loc.boundaryOwnerLoadError, error: true);
    }
  }

  void _showReportSheet(
    BuildContext sheetCtx,
    PlotMapBloc bloc,
    String boundaryId,
  ) {
    final controller = TextEditingController();
    final submit = ReportSubmitter(widget.report);
    showModalBottomSheet<void>(
      context: sheetCtx,
      showDragHandle: true,
      builder: (noteCtx) {
        final loc = AppLocalizations.of(noteCtx);
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, 16 + MediaQuery.of(noteCtx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.boundaryReport,
                  style: Theme.of(noteCtx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: loc.boundaryReportNoteHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final note = controller.text.trim();
                    if (note.isEmpty) return;
                    final ok = await submit(boundaryId, note);
                    if (!noteCtx.mounted) return;
                    Navigator.of(noteCtx).pop();
                    showAppToast(
                      noteCtx,
                      ok
                          ? loc.boundaryReportSent
                          : loc.boundaryReportError,
                      error: !ok,
                    );
                  },
                  child: Text(loc.boundaryReportSubmit),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LayerToggle extends StatelessWidget {
  const _LayerToggle();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final layer = context.select<PlotMapBloc, MapLayer>(
        (b) => b.state.layer);
    return SegmentedButton<MapLayer>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
            value: MapLayer.street,
            icon: const Icon(Icons.map_outlined),
            label: Text(loc.boundaryLayerStreet)),
        ButtonSegment(
            value: MapLayer.satellite,
            icon: const Icon(Icons.satellite_alt_outlined),
            label: Text(loc.boundaryLayerSatellite)),
      ],
      selected: {layer},
      onSelectionChanged: (s) => context
          .read<PlotMapBloc>()
          .add(PlotMapLayerChanged(s.first)),
    );
  }
}

/// Small indirection so the report use case can be swapped in tests.
class ReportSubmitter {
  ReportSubmitter(this._override);

  final Future<void> Function(String, String)? _override;

  Future<bool> call(String boundaryId, String note) async {
    try {
      if (_override != null) {
        await _override(boundaryId, note);
      } else {
        await ReportBoundaryProblem(
          PlotBoundaryRepositoryImpl(apiClient: sl<ApiClient>()),
        )(boundaryId, note);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
