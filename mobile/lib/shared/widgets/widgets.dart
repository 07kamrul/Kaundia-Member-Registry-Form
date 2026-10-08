import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_theme.dart';

/// Shared widgets mirroring the Angular web primitives.

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.actions, this.icon});

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gutter = context.pageGutter;
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: (context.isCompact
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.headlineSmall)
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle!, style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: 8),
            Wrap(spacing: 4, runSpacing: 4, children: actions!),
          ],
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.onTap,
    this.padding,
    this.margin,
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  /// Defaults to the responsive page gutter; pass [EdgeInsets.zero] inside grids.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: margin ?? EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title!, style: theme.textTheme.titleMedium),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

enum AppButtonVariant { primary, secondary, danger, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expanded = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expanded;

  /// Shows a spinner and disables the button while an action is in flight.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = loading ? null : onPressed;
    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: action,
          child: _child(),
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: action,
          child: _child(),
        ),
      AppButtonVariant.danger => FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
          ),
          onPressed: action,
          child: _child(),
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: action,
          child: _child(),
        ),
    };
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _child() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      );
}

enum StatusKind { pending, approved, rejected, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.kind, this.label});

  final StatusKind kind;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (Color bg, Color fg, String text) = switch (kind) {
      StatusKind.pending => (
          const Color(0xFFF1E4C3),
          const Color(0xFF8A611A),
          label ?? loc.commonStatusPending,
        ),
      StatusKind.approved => (
          const Color(0xFFE5EDE1),
          const Color(0xFF2E5138),
          label ?? loc.commonStatusApproved,
        ),
      StatusKind.rejected => (
          const Color(0xFFF7E2DE),
          const Color(0xFF9C3A2C),
          label ?? loc.commonStatusRejected,
        ),
      StatusKind.neutral => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
          label ?? '',
        ),
    };
    // In dark mode the pale fills glare; invert to a tinted fill + light text.
    final fill = isDark && kind != StatusKind.neutral ? fg.withValues(alpha: 0.35) : bg;
    final ink = isDark && kind != StatusKind.neutral ? bg : fg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon, this.action});

  final String message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.inbox_outlined,
                  size: 36,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, color: theme.colorScheme.error, size: 32),
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                AppButton(
                  label: AppLocalizations.of(context).commonRetry,
                  variant: AppButtonVariant.secondary,
                  icon: Icons.refresh,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key, this.lines = 4, this.height = 64});

  final int lines;
  final double height;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < widget.lines; i++) ...[
              Container(
                width: double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class AppTabs extends StatelessWidget {
  const AppTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: [for (final l in labels) Tab(text: l)],
      onTap: onChanged,
    );
  }
}

/// Checkbox with the Angular look: white fill, black 1.5px border, black check
/// in both states/themes. Falls back to theme styling in dark mode via onSurface.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.label, required this.value, this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: value
                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class AppDialog {
  const AppDialog._();

  static Future<void> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) {
    final loc = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel ?? loc.commonCancel),
          ),
          if (destructive)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmLabel ?? loc.commonConfirmAction),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmLabel ?? loc.commonConfirmAction),
            ),
        ],
      ),
    );
  }
}

void showAppToast(BuildContext context, String message, {bool error = false}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: theme.colorScheme.surface,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: error ? theme.colorScheme.error : null,
        width: context.isCompact ? null : 480,
      ),
    );
}

/// Responsive list-card replacement for wide data tables (mirrors the Angular
/// `.data-table-cards` responsive idiom). One column on phones, a grid of
/// cards on tablets.
class AppDataTableCards<T> extends StatelessWidget {
  const AppDataTableCards({
    super.key,
    required this.items,
    required this.rowBuilder,
    this.onRowTap,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) rowBuilder;
  final void Function(T item)? onRowTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(message: AppLocalizations.of(context).commonNoData);
    }
    Widget row(T item) => GestureDetector(
          onTap: onRowTap == null ? null : () => onRowTap!(item),
          child: rowBuilder(context, item),
        );
    if (context.isCompact) {
      return Column(children: [for (final item in items) row(item)]);
    }
    return ResponsiveGrid(
      minItemWidth: 340,
      spacing: 0,
      maxColumns: 3,
      children: [for (final item in items) row(item)],
    );
  }
}

/// Compact KPI tile: tinted icon, big value, label. Use inside [ResponsiveGrid].
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: theme.textTheme.titleLarge?.copyWith(color: color),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label/value row for detail cards. Stacks vertically on narrow widths so
/// long Bangla labels never squash the value.
class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final labelText = Text(label, style: theme.textTheme.bodySmall);
                final valueText = Text(
                  value.isEmpty ? '—' : value,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                );
                if (c.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [labelText, const SizedBox(height: 2), valueText],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: c.maxWidth * 0.4, child: labelText),
                    Expanded(child: valueText),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Muted heading separating groups of content on a page.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(context.pageGutter, 16, context.pageGutter, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Standard scrollable page body: width-capped, safe-area aware, optional
/// pull-to-refresh. Use [Breakpoints.formMaxWidth] as [maxWidth] for forms.
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.onRefresh,
    this.maxWidth = Breakpoints.contentMaxWidth,
    this.padding = const EdgeInsets.only(bottom: 24),
  });

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        ResponsiveCenter(
          maxWidth: maxWidth,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ],
    );
    final body = SafeArea(top: false, child: list);
    return onRefresh == null ? body : RefreshIndicator(onRefresh: onRefresh!, child: body);
  }
}
