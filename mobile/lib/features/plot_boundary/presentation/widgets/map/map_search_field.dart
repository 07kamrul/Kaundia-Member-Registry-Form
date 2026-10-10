import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Floating pill search box over the map. The controller text drives the
/// clear button, so it stays correct however the text changes.
class MapSearchField extends StatelessWidget {
  const MapSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCleared,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCleared;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Material(
      elevation: 3,
      color: theme.colorScheme.surface,
      shape: const StadiumBorder(),
      child: SizedBox(
        height: 48,
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            prefixIcon: const Icon(Icons.search, size: 20),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, __) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      tooltip: loc.plotMapSearchClear,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onCleared,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
