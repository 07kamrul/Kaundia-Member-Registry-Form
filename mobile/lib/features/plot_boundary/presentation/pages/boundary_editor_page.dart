import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_config.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../member/domain/finance_entities.dart' show toBanglaDigits;
import '../../../../shared/widgets/widgets.dart';
import '../../domain/boundary_validation.dart';
import '../../domain/geo.dart';
import '../../domain/plot_boundary_entities.dart';
import '../../domain/plot_boundary_failure.dart';
import '../bloc/boundary_editor_bloc.dart';
import '../widgets/boundary_disclaimer_banner.dart';

/// Tap-to-draw polygon editor: vertices are added by tapping the map, moved
/// by dragging their markers, removed via long-press / list. Save POSTs (or
/// PUTs when editing) and the boundary goes to pending_review.
class BoundaryEditorPage extends StatelessWidget {
  const BoundaryEditorPage({super.key, this.createBloc, this.editing});

  final BoundaryEditorBloc Function()? createBloc;

  /// Existing boundary to edit (PUT instead of POST).
  final PlotBoundary? editing;

  static const pageRoute = '/plot-map/draw';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          (createBloc?.call() ?? BoundaryEditorBloc())
            ..add(EditorStarted(editing: editing)),
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView();

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.boundaryEditorTitle)),
      body: BlocConsumer<BoundaryEditorBloc, BoundaryEditorState>(
        listener: (context, state) {
          if (state.status == EditorStatus.saved) {
            showAppToast(context, loc.boundarySaveSuccess);
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (state.status == EditorStatus.loading) {
            return const SkeletonLoader(lines: 4);
          }
          if (state.status == EditorStatus.failure &&
              state.properties.isEmpty) {
            return InlineError(
              message: _failureMessage(state.failureKind, loc),
              onRetry: () => context
                  .read<BoundaryEditorBloc>()
                  .add(const EditorStarted()),
            );
          }
          return Column(
            children: [
              const BoundaryDisclaimerBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: _PropertyPicker(state: state),
              ),
              Expanded(child: _EditorMap(mapController: _mapController)),
              _EditorToolbar(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _PropertyPicker extends StatelessWidget {
  const _PropertyPicker({required this.state});

  final BoundaryEditorState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final options = state.availableProperties.isEmpty &&
            state.selectedProperty != null
        ? [state.selectedProperty!]
        : state.availableProperties;
    if (options.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.info_outline, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(loc.boundaryEditorNoProperty,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      );
    }
    return InputDecorator(
      decoration: InputDecoration(
        isDense: true,
        labelText: loc.boundaryEditorPropertyLabel,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          isExpanded: true,
          value: state.selectedPropertyId,
          items: [
            for (final p in options)
              DropdownMenuItem(
                value: p.propertyId,
                child: Text(
                  'RS ${p.rsDag ?? '—'} / CS ${p.csDag ?? '—'}'
                  '${p.landQuantity == null ? '' : ' · ${p.landQuantity} শতাংশ'}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (id) {
            if (id != null) {
              context
                  .read<BoundaryEditorBloc>()
                  .add(EditorPropertyChanged(id));
            }
          },
        ),
      ),
    );
  }
}

class _EditorMap extends StatelessWidget {
  const _EditorMap({required this.mapController});

  final MapController mapController;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BoundaryEditorBloc>();
    final bbox = _societyBbox();
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: bbox != null
            ? LatLng((bbox.minLat + bbox.maxLat) / 2,
                (bbox.minLng + bbox.maxLng) / 2)
            : const LatLng(23.8103, 90.4125),
        initialZoom: 16,
        onTap: (_, latLng) => bloc.add(EditorVertexAdded(latLng)),
      ),
      children: [
        TileLayer(
          urlTemplate: AppConfig.mapTileUrl,
          userAgentPackageName: 'bd.kaundia.app',
        ),
        BlocBuilder<BoundaryEditorBloc, BoundaryEditorState>(
          buildWhen: (a, b) => a.vertices != b.vertices,
          builder: (context, state) {
            final vertices = state.vertices;
            return Stack(
              children: [
                if (vertices.length >= 3)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: vertices,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.25),
                        borderColor: Theme.of(context).colorScheme.primary,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                if (vertices.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: vertices,
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (var i = 0; i < vertices.length; i++)
                      _vertexMarker(context, bloc, i, vertices[i]),
                  ],
                ),
              ],
            );
          },
        ),
        RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  Marker _vertexMarker(
    BuildContext context,
    BoundaryEditorBloc bloc,
    int index,
    LatLng point,
  ) {
    return Marker(
      point: point,
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: GestureDetector(
        onPanUpdate: (details) {
          // Convert the pixel delta to a geographic offset around the vertex.
          final camera = mapController.camera;
          final projected = camera.project(point);
          final moved = camera.pointToLatLng(
            projected +
                Point<double>(
                  details.delta.dx.toDouble(),
                  details.delta.dy.toDouble(),
                ),
          );
          bloc.add(EditorVertexMoved(index, moved));
        },
        onLongPress: () => bloc.add(EditorVertexRemoved(index)),
        child: Tooltip(
          message: '${index + 1}',
          child: Icon(
            Icons.location_on,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
        ),
      ),
    );
  }

  SocietyBbox? _societyBbox() {
    final raw = AppConfig.societyBboxRaw;
    if (raw.isEmpty) return null;
    try {
      return SocietyBbox.parse(raw);
    } on FormatException {
      return null;
    }
  }
}

class _EditorToolbar extends StatelessWidget {
  const _EditorToolbar({required this.state});

  final BoundaryEditorState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<BoundaryEditorBloc>();
    final theme = Theme.of(context);
    final validation = state.validation;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${loc.boundaryEditorVertices(
                      _digits(context, '${state.vertices.length}'),
                    )} · '
                    '${loc.boundaryAreaValues(
                      _digits(context, validation.areaSqm.toStringAsFixed(1)),
                      _digits(
                          context, validation.areaShotangsho.toStringAsFixed(2)),
                    )} '
                    '(${loc.boundaryAreaEstimateTag})',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: loc.boundaryEditorUndo,
                  onPressed: state.canUndo
                      ? () => bloc.add(const EditorUndoPressed())
                      : null,
                  icon: const Icon(Icons.undo),
                ),
                IconButton(
                  tooltip: loc.boundaryEditorClear,
                  onPressed: state.vertices.isEmpty
                      ? null
                      : () => bloc.add(const EditorCleared()),
                  icon: const Icon(Icons.layers_clear_outlined),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: state.canSave && state.status != EditorStatus.saving
                      ? () => bloc.add(const EditorSaveRequested())
                      : null,
                  child: state.status == EditorStatus.saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(loc.boundaryEditorSave),
                ),
              ],
            ),
            if (validation.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorLabel(validation.error!, loc),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            if (state.status == EditorStatus.failure &&
                state.failureKind != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _failureMessage(state.failureKind, loc),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                loc.boundaryEditorAddHint,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _digits(BuildContext context, String text) =>
      Localizations.localeOf(context).languageCode == 'bn'
          ? toBanglaDigits(text)
          : text;
}

String _errorLabel(BoundaryError error, AppLocalizations loc) =>
    switch (error) {
      BoundaryError.tooFewPoints => loc.boundaryErrorTooFewPoints,
      BoundaryError.selfIntersecting => loc.boundaryErrorSelfIntersecting,
      BoundaryError.outsideSociety => loc.boundaryErrorOutsideSociety,
      BoundaryError.zeroArea => loc.boundaryErrorZeroArea,
      BoundaryError.tooManyVertices => loc.boundaryErrorTooManyVertices,
    };

String _failureMessage(
  PlotBoundaryFailureKind? kind,
  AppLocalizations loc,
) =>
    switch (kind) {
      PlotBoundaryFailureKind.network => loc.commonNetworkError,
      PlotBoundaryFailureKind.selfIntersecting =>
        loc.boundaryErrorSelfIntersecting,
      PlotBoundaryFailureKind.outsideSociety => loc.boundaryErrorOutsideSociety,
      PlotBoundaryFailureKind.zeroArea => loc.boundaryErrorZeroArea,
      PlotBoundaryFailureKind.tooManyVertices =>
        loc.boundaryErrorTooManyVertices,
      PlotBoundaryFailureKind.invalidGeometry =>
        loc.boundaryErrorInvalidGeometry,
      PlotBoundaryFailureKind.notYourProperty =>
        loc.boundaryErrorNotYourProperty,
      PlotBoundaryFailureKind.boundaryExists => loc.boundaryErrorBoundaryExists,
      PlotBoundaryFailureKind.rateLimited => loc.boundaryErrorRateLimited,
      PlotBoundaryFailureKind.notApproved => loc.boundaryErrorNotApproved,
      PlotBoundaryFailureKind.other || null => loc.boundaryErrorGeneric,
    };
