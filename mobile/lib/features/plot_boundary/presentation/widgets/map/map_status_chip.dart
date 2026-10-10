import 'package:flutter/material.dart';

enum MapStatusTone { info, warning, error }

/// Small floating status pill (loading / partial data / error + retry).
class MapStatusChip extends StatelessWidget {
  const MapStatusChip({
    super.key,
    required this.message,
    this.tone = MapStatusTone.info,
    this.showSpinner = false,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final MapStatusTone tone;
  final bool showSpinner;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      MapStatusTone.info => (scheme.surface, scheme.onSurface),
      MapStatusTone.warning => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      MapStatusTone.error => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Semantics(
      liveRegion: true,
      child: Material(
        elevation: 3,
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSpinner) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 12.5, color: foreground),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 40),
                    foregroundColor: foreground,
                  ),
                  child: Text(actionLabel!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
