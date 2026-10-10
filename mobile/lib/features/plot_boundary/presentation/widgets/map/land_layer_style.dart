import 'package:flutter/material.dart';

import '../../../domain/land_entities.dart';

/// Fill/stroke of an official land layer (mirrors Angular `externalStyle`).
class LandLayerStyle {
  const LandLayerStyle({
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  final Color fill;
  final Color stroke;
  final double strokeWidth;

  static const LandLayerStyle bds = LandLayerStyle(
    fill: Color(0x332B50E0),
    stroke: Color(0xFF1A3FD4),
    strokeWidth: 2,
  );

  static const LandLayerStyle rajuk = LandLayerStyle(
    fill: Color(0x4DB7C94A),
    stroke: Color(0xFF7A8B12),
    strokeWidth: 1.5,
  );

  /// The plot found by a dag search stays orange across reloads.
  static const LandLayerStyle highlight = LandLayerStyle(
    fill: Color(0x80E65100),
    stroke: Color(0xFFE65100),
    strokeWidth: 4,
  );

  static LandLayerStyle of(LandLayer layer) => switch (layer) {
        LandLayer.bds => bds,
        LandLayer.rajuk => rajuk,
      };
}

/// Colour of the zoomed-in BDS dag labels.
const Color kDagLabelColor = Color(0xFF14308F);

/// Society-blue dot for the member's own position.
const Color kMyLocationColor = Color(0xFF1E66D0);
