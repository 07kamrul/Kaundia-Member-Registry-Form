import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// "Member-marked approximate boundary" notice over the map. Dismissible for
/// the rest of the app session (Angular keeps this in sessionStorage).
class MapDisclaimer extends StatefulWidget {
  const MapDisclaimer({super.key});

  static bool _dismissedThisSession = false;

  /// Test hook: forget the session-wide dismissal.
  static void resetSession() => _dismissedThisSession = false;

  @override
  State<MapDisclaimer> createState() => _MapDisclaimerState();
}

class _MapDisclaimerState extends State<MapDisclaimer> {
  @override
  Widget build(BuildContext context) {
    if (MapDisclaimer._dismissedThisSession) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: Material(
        elevation: 3,
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 16, color: scheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.boundaryDisclaimer,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              IconButton(
                tooltip: loc.commonClose,
                icon: Icon(Icons.close,
                    size: 18, color: scheme.onSecondaryContainer),
                onPressed: () => setState(
                  () => MapDisclaimer._dismissedThisSession = true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
