import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/config/app_config.dart';
import '../../../domain/geo.dart';
import '../../../domain/land_entities.dart';
import '../../../domain/plot_boundary_entities.dart';
import '../../bloc/plot_map_bloc.dart';
import 'boundary_polygon_layer.dart';
import 'land_label_layer.dart';
import 'land_layer_style.dart';
import 'land_polygon_layer.dart';

/// Zoom limits of the society map (mirrors Angular minZoom/maxZoom).
const double kMapMinZoom = 12;
const double kMapMaxZoom = 19;

/// Slack around the society bbox the camera may roam in (Leaflet `pad(0.05)`).
const double kMapBoundsPadding = 0.05;

/// The map itself: basemap + the layers of the active [mode]. Purely
/// presentational — the page owns controller, blocs and gesture handling.
class PlotMapCanvas extends StatelessWidget {
  const PlotMapCanvas({
    super.key,
    required this.controller,
    required this.mode,
    required this.basemap,
    required this.society,
    required this.features,
    required this.boundaryQuery,
    required this.highlightedBoundaryId,
    required this.landCollection,
    required this.highlightDag,
    required this.myLocation,
    required this.onTap,
    required this.onCameraChanged,
    this.tileProvider,
  });

  final MapController controller;
  final MapMode mode;
  final MapLayer basemap;
  final SocietyBbox? society;
  final List<BoundaryFeature> features;
  final String boundaryQuery;
  final String? highlightedBoundaryId;
  final LandCollection? landCollection;
  final String? highlightDag;
  final LatLng? myLocation;
  final ValueChanged<LatLng> onTap;
  final ValueChanged<MapCamera> onCameraChanged;

  /// Overrides the network tile provider (tests).
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    final area = society?.padded(kMapBoundsPadding);
    final landLayer = mode.landLayer;
    final collection = landCollection;
    final isStreet = basemap == MapLayer.street;

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: const LatLng(
          AppConfig.societyCenterLat,
          AppConfig.societyCenterLng,
        ),
        initialZoom: AppConfig.societyDefaultZoom,
        minZoom: kMapMinZoom,
        maxZoom: kMapMaxZoom,
        cameraConstraint: area == null
            ? const CameraConstraint.unconstrained()
            : CameraConstraint.containCenter(
                bounds: LatLngBounds(
                  LatLng(area.minLat, area.minLng),
                  LatLng(area.maxLat, area.maxLng),
                ),
              ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (_, point) => onTap(point),
        onPositionChanged: (camera, _) => onCameraChanged(camera),
      ),
      children: [
        TileLayer(
          urlTemplate:
              isStreet ? AppConfig.mapTileUrl : AppConfig.satelliteTileUrl,
          maxZoom: kMapMaxZoom,
          tileProvider: tileProvider,
          userAgentPackageName: 'bd.kaundia.app',
        ),
        if (mode == MapMode.boundaries)
          BoundaryPolygonLayer(
            features: features,
            query: boundaryQuery,
            highlightedId: highlightedBoundaryId,
          ),
        if (landLayer != null && collection != null)
          LandPolygonLayer(
            layer: landLayer,
            collection: collection,
            highlightDag: highlightDag,
          ),
        if (landLayer == LandLayer.bds && collection != null)
          LandLabelLayer(collection: collection),
        if (myLocation != null)
          MarkerLayer(markers: [
            Marker(
              point: myLocation!,
              width: 22,
              height: 22,
              child: const _MyLocationDot(),
            ),
          ]),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              isStreet ? 'OpenStreetMap contributors' : 'Esri World Imagery',
            ),
          ],
        ),
      ],
    );
  }
}

class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: kMyLocationColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 6),
        ],
      ),
    );
  }
}
