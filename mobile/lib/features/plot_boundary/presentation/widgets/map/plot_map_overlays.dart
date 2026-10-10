import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/land_entities.dart';
import '../../bloc/land_map_bloc.dart';
import '../../bloc/my_location_cubit.dart';
import '../../bloc/plot_map_bloc.dart';
import 'map_disclaimer.dart';
import 'map_legend.dart';
import 'map_status_chip.dart';
import 'map_top_bar.dart';

/// Top overlay: progress line + [MapTopBar] fed from the blocs.
class PlotMapTopOverlay extends StatelessWidget {
  const PlotMapTopOverlay({
    super.key,
    required this.searchController,
    required this.canDraw,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onSearchCleared,
    required this.onLocate,
    required this.onDraw,
    required this.onModeChanged,
  });

  final TextEditingController searchController;
  final bool canDraw;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchCleared;
  final VoidCallback onLocate;
  final VoidCallback onDraw;
  final ValueChanged<MapMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<LandMapBloc, LandMapState>(
      builder: (context, land) {
        return BlocBuilder<MyLocationCubit, MyLocationState>(
          builder: (context, location) {
            final notices = [
              if (land.dagNotFound) loc.plotMapViewsDagNotFound,
              if (location.status == MyLocationStatus.failure)
                loc.plotMapLocationError,
              if (location.status == MyLocationStatus.outsideSociety)
                loc.plotMapOutsideSociety,
            ];
            return MapTopBar(
              mode: land.mode,
              searchController: searchController,
              searchHint: switch (land.mode) {
                MapMode.boundaries => loc.boundarySearchDagHint,
                MapMode.bds => loc.plotMapViewsBdsSearchPlaceholder,
                MapMode.rajuk => loc.plotMapViewsRsSearchPlaceholder,
              },
              onSearchChanged: onSearchChanged,
              onSearchSubmitted: onSearchSubmitted,
              onSearchCleared: onSearchCleared,
              isLocating: location.status == MyLocationStatus.locating,
              onLocate: onLocate,
              canDraw: canDraw,
              onDraw: onDraw,
              onModeChanged: onModeChanged,
              notices: notices,
            );
          },
        );
      },
    );
  }
}

/// Thin progress line while the active layer is loading.
class PlotMapProgress extends StatelessWidget {
  const PlotMapProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final plotLoading = context.select<PlotMapBloc, bool>(
      (b) => b.state.status == PlotMapStatus.loading,
    );
    final land = context.watch<LandMapBloc>().state;
    final loading = land.mode == MapMode.boundaries
        ? plotLoading
        : land.isLoading;
    return loading
        ? const LinearProgressIndicator(minHeight: 3)
        : const SizedBox(height: 3);
  }
}

/// Bottom overlay: legend (boundaries view), basemap switch, load status and
/// the dismissible disclaimer.
class PlotMapBottomOverlay extends StatelessWidget {
  const PlotMapBottomOverlay({
    super.key,
    required this.basemap,
    required this.onToggleBasemap,
    required this.onRetryBoundaries,
    required this.onRetryLand,
  });

  final MapLayer basemap;
  final VoidCallback onToggleBasemap;
  final VoidCallback onRetryBoundaries;
  final VoidCallback onRetryLand;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final land = context.watch<LandMapBloc>().state;
    final plotFailed = context.select<PlotMapBloc, bool>(
      (b) => b.state.status == PlotMapStatus.failure,
    );
    final isBoundaries = land.mode == MapMode.boundaries;

    final Widget? status = isBoundaries
        ? (plotFailed
            ? MapStatusChip(
                message: loc.boundaryLoadError,
                tone: MapStatusTone.error,
                actionLabel: loc.commonRetry,
                onAction: onRetryBoundaries,
              )
            : null)
        : (land.isLoading
            ? MapStatusChip(
                message: loc.plotMapViewsLoading,
                showSpinner: true,
              )
            : land.hasError
                ? MapStatusChip(
                    message: loc.plotMapViewsLoadError,
                    tone: MapStatusTone.error,
                    actionLabel: loc.commonRetry,
                    onAction: onRetryLand,
                  )
                : land.isTruncated
                    ? MapStatusChip(
                        message: loc.plotMapViewsPartialData,
                        tone: MapStatusTone.warning,
                      )
                    : null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: isBoundaries ? const MapLegend() : const SizedBox(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: 'plot_map_basemap',
              tooltip: basemap == MapLayer.street
                  ? loc.boundaryLayerSatellite
                  : loc.boundaryLayerStreet,
              onPressed: onToggleBasemap,
              child: Icon(
                basemap == MapLayer.street
                    ? Icons.satellite_alt_outlined
                    : Icons.map_outlined,
              ),
            ),
          ],
        ),
        if (status != null) ...[
          const SizedBox(height: 8),
          Center(child: status),
        ],
        const SizedBox(height: 8),
        const MapDisclaimer(),
      ],
    );
  }
}
