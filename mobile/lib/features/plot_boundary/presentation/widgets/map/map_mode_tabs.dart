import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/land_entities.dart';

/// Segmented switcher between member boundaries, the BDS dag map and the
/// RAJUK masterplan (Angular `.map-modes`).
class MapModeTabs extends StatelessWidget {
  const MapModeTabs({super.key, required this.mode, required this.onChanged});

  final MapMode mode;
  final ValueChanged<MapMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final tabs = [
      (MapMode.boundaries, Icons.edit_location_alt_outlined,
          loc.plotMapViewsBoundaries, loc.plotMapViewsBoundariesHint),
      (MapMode.bds, Icons.map_outlined, loc.plotMapViewsBds,
          loc.plotMapViewsBdsHint),
      (MapMode.rajuk, Icons.description_outlined, loc.plotMapViewsRajuk,
          loc.plotMapViewsRajukHint),
    ];
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: loc.plotMapViewsTitle,
      child: Material(
        elevation: 3,
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (final (value, icon, label, hint) in tabs)
                Expanded(
                  child: _ModeTab(
                    icon: icon,
                    label: label,
                    hint: hint,
                    selected: value == mode,
                    onTap: () => onChanged(value),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.icon,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    // The inner Text already provides the label; adding one here would make
    // screen readers announce it twice.
    return Semantics(
      button: true,
      selected: selected,
      child: Tooltip(
        message: hint,
        child: Material(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: foreground),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.15,
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
