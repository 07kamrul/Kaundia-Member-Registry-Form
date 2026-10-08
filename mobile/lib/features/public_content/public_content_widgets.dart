import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/app_theme.dart';

/// Shared presentation bits for the public notices / events screens.

/// App bar for public pages. When the page was reached with `go` (no route to
/// pop), the leading button falls back to [fallbackRoute].
PreferredSizeWidget publicAppBar(
  BuildContext context, {
  required String title,
  required String fallbackRoute,
  required String fallbackTooltip,
}) {
  return AppBar(
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    leading: context.canPop()
        ? null
        : IconButton(
            tooltip: fallbackTooltip,
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(fallbackRoute),
          ),
  );
}

/// Muted intro line under the app bar.
class PublicIntro extends StatelessWidget {
  const PublicIntro({super.key, required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gutter = context.pageGutter;
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small icon + text meta line (date, location) for list cards.
class MetaLine extends StatelessWidget {
  const MetaLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Calendar-style day/month block shown on event cards.
class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.date, this.muted = false});

  final DateTime date;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = muted ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primary;
    final fg = muted ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onPrimary;
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat.MMM().format(date).toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: muted ? fg : AppColors.amber200,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            DateFormat.d().format(date),
            style: theme.textTheme.titleLarge?.copyWith(color: fg, height: 1.1),
          ),
        ],
      ),
    );
  }
}

/// Back-to-list link shown above detail cards.
class BackToListLink extends StatelessWidget {
  const BackToListLink({super.key, required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final gutter = context.pageGutter;
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter - 8, 8, gutter, 0),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: () => context.go(route),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: Text(label),
        ),
      ),
    );
  }
}
