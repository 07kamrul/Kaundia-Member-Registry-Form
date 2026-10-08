import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/widgets.dart';

/// Layout building blocks shared by the management pages (record cards,
/// filter chips, KPI summaries, two-pane detail layout, sticky action bar).
/// Re-exported from `management_widgets.dart`.

/// Circular initial avatar for list records.
class ManagementAvatar extends StatelessWidget {
  const ManagementAvatar({super.key, required this.name, this.radius = 20});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trimmed = name.trim();
    final initial =
        trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}

/// Consistent list-record card: header (avatar, title, subtitle, badge),
/// optional detail rows, and a right-aligned wrapping action row.
class ManagementRecordCard extends StatelessWidget {
  const ManagementRecordCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.badge,
    this.children = const [],
    this.actions = const [],
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? badge;
  final List<Widget> children;
  final List<Widget> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(Theme.of(context)),
              if (children.isNotEmpty) ...[
                const Divider(height: 20),
                ...children,
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
        if (badge != null) ...[const SizedBox(width: 8), badge!],
      ],
    );
  }
}

/// Page-gutter padded grid of record cards: 1 column on phones, 2-3 on
/// tablets / landscape.
class ManagementRecordGrid extends StatelessWidget {
  const ManagementRecordGrid({
    super.key,
    required this.children,
    this.minItemWidth = 340,
    this.maxColumns = 3,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 6),
      child: ResponsiveGrid(
        minItemWidth: minItemWidth,
        maxColumns: maxColumns,
        children: children,
      ),
    );
  }
}

/// Wrapping single-select chip bar used for status / category filters.
class ManagementFilterChips<T> extends StatelessWidget {
  const ManagementFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.label,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(label!,
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, text) in options)
                ChoiceChip(
                  label: Text(text),
                  selected: value == selected,
                  onSelected: (_) {
                    if (value != selected) onSelected(value);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One KPI shown by [ManagementStatSummary].
class ManagementStat {
  const ManagementStat({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;
}

/// KPI summary: one compact card with side-by-side figures on phones, a grid
/// of [StatTile]s on tablets.
class ManagementStatSummary extends StatelessWidget {
  const ManagementStatSummary({super.key, required this.stats, this.padding});

  final List<ManagementStat> stats;

  /// Defaults to the page gutter; pass a smaller value inside padded panes.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final gutter = context.pageGutter;
    final padding = this.padding ?? EdgeInsets.fromLTRB(gutter, 4, gutter, 8);
    if (!context.isCompact) {
      return Padding(
        padding: padding,
        child: ResponsiveGrid(
          minItemWidth: 200,
          children: [
            for (final s in stats)
              StatTile(
                  label: s.label,
                  value: s.value,
                  icon: s.icon,
                  accent: s.accent),
          ],
        ),
      );
    }
    final divider = Theme.of(context).colorScheme.outlineVariant;
    return Padding(
      padding: padding,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) Container(width: 1, height: 40, color: divider),
                Expanded(child: _MiniStat(stat: stats[i])),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.stat});

  final ManagementStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = stat.accent ?? theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat.icon, size: 18, color: color),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stat.value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            stat.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Detail-page body: two columns once the content area is wide enough,
/// otherwise a single readable column capped at [Breakpoints.formMaxWidth].
class ManagementTwoPane extends StatelessWidget {
  const ManagementTwoPane({
    super.key,
    required this.primary,
    required this.secondary,
  });

  /// Below this content width the panes stack.
  static const double _twoPaneMinWidth = 840;

  final List<Widget> primary;
  final List<Widget> secondary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _twoPaneMinWidth) {
          return ResponsiveCenter(
            maxWidth: Breakpoints.formMaxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [...primary, ...secondary],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: secondary),
            ),
          ],
        );
      },
    );
  }
}

/// Sticky bottom action bar (approve / reject on detail pages). Children get
/// equal width.
class ManagementActionBar extends StatelessWidget {
  const ManagementActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gutter = context.pageGutter;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 12),
          child: ResponsiveCenter(
            maxWidth: Breakpoints.formMaxWidth,
            child: Row(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: children[i]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Detail-page section card: [AppCard] with a muted section icon; spacing
/// comes from the surrounding page gutter (see [ManagementTwoPane]).
class ManagementSectionCard extends StatelessWidget {
  const ManagementSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
  });

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AppCard(
      title: title,
      margin: const EdgeInsets.symmetric(vertical: 6),
      trailing: icon == null
          ? null
          : Icon(icon, size: 20, color: primary.withValues(alpha: 0.7)),
      child: child,
    );
  }
}

/// Muted one-line note for empty sections ("No nominees", ...).
class ManagementMutedText extends StatelessWidget {
  const ManagementMutedText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

/// Tinted callout (warnings / notices) with optional trailing action.
class ManagementCallout extends StatelessWidget {
  const ManagementCallout({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.error = false,
    this.action,
  });

  final String message;
  final IconData icon;
  final bool error;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = error ? scheme.error : scheme.secondary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          if (action != null)
            Align(alignment: Alignment.centerRight, child: action),
        ],
      ),
    );
  }
}
