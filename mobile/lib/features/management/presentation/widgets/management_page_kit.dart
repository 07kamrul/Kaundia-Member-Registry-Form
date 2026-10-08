import 'package:flutter/material.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_theme.dart';

/// Layout helpers shared by the finance, society-cost, fee-settings, roadmap,
/// events and notices management pages: width-capped form sheets, wrapping
/// filter panels, card grids, pager and pull-to-refresh plumbing helpers.

/// Max width for form sheets / dialogs on tablets and landscape phones.
const double kFormSheetMaxWidth = 560;

/// Bottom padding so the last card is never hidden behind a FAB.
const double kFabClearance = 96;

/// Modal bottom sheet capped at [kFormSheetMaxWidth], safe-area aware and
/// keyboard friendly. Pair with [FormSheet] for the content.
Future<T?> showFormSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: kFormSheetMaxWidth),
    builder: builder,
  );
}

/// Standard form-sheet body: title row with close button, scrollable fields
/// and a pinned action bar that stays above the keyboard.
class FormSheet extends StatelessWidget {
  const FormSheet({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.icon,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;

  /// Rendered side by side with equal width (primary action last).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FormSheetHeader(title: title, subtitle: subtitle, icon: icon),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: children,
              ),
            ),
          ),
          if (actions.isNotEmpty) _FormSheetActions(actions: actions),
        ],
      ),
    );
  }
}

class _FormSheetHeader extends StatelessWidget {
  const _FormSheetHeader({required this.title, this.subtitle, this.icon});

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _FormSheetActions extends StatelessWidget {
  const _FormSheetActions({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            spacing: 12,
            children: [for (final a in actions) Expanded(child: a)],
          ),
        ),
      ),
    );
  }
}

/// Two fields side by side when there is room, stacked on narrow phones.
class FieldPair extends StatelessWidget {
  const FieldPair({
    super.key,
    required this.first,
    required this.second,
    this.breakpoint = 400,
  });

  final Widget first;
  final Widget second;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [first, second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [Expanded(child: first), Expanded(child: second)],
        );
      },
    );
  }
}

/// Filter card whose fields flow into 1–4 columns depending on width, with
/// an optional action row underneath.
class FilterPanel extends StatelessWidget {
  const FilterPanel({
    super.key,
    required this.fields,
    this.actions = const [],
    this.minFieldWidth = 220,
  });

  final List<Widget> fields;
  final List<Widget> actions;
  final double minFieldWidth;

  @override
  Widget build(BuildContext context) {
    final gutter = context.pageGutter;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: gutter, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveGrid(
              minItemWidth: minFieldWidth,
              maxColumns: 4,
              children: fields,
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dropdown that always fills its width, ellipsizes long labels and resets
/// when [value] changes from outside (e.g. after "reset filters").
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.prefixIcon,
  });

  final String label;
  final T? value;
  final List<(T?, String)> options;
  final ValueChanged<T?>? onChanged;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey<Object?>(value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
      items: [
        for (final (optionValue, text) in options)
          DropdownMenuItem<T>(
            value: optionValue,
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Lays cards out in a responsive grid within the page gutter. Cards placed
/// here should use `margin: EdgeInsets.zero`.
class CardGrid extends StatelessWidget {
  const CardGrid({
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
      padding: EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 6),
      child: ResponsiveGrid(
        minItemWidth: minItemWidth,
        maxColumns: maxColumns,
        children: children,
      ),
    );
  }
}

/// "Add" floating action button: icon-only on phones, extended on tablets.
class AddFab extends StatelessWidget {
  const AddFab({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (context.isCompact) {
      return FloatingActionButton(
        heroTag: null,
        tooltip: label,
        onPressed: onPressed,
        child: Icon(icon),
      );
    }
    return FloatingActionButton.extended(
      heroTag: null,
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

/// Small icon + text line used for card metadata (date, category, place).
class MetaText extends StatelessWidget {
  const MetaText({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
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

/// Prev / "page x of y" / next control.
class PageStepper extends StatelessWidget {
  const PageStepper({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.outlined(
            tooltip: material.previousPageTooltip,
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          IconButton.outlined(
            tooltip: material.nextPageTooltip,
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// Thin progress bar shown above existing content while it reloads, so the
/// list does not flash back to a skeleton.
class ReloadingBar extends StatelessWidget {
  const ReloadingBar({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: visible
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: context.pageGutter),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: const LinearProgressIndicator(),
              ),
            )
          : null,
    );
  }
}

/// Dialog content constrained to a readable width on tablets.
class DialogBody extends StatelessWidget {
  const DialogBody({super.key, required this.child, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.maxFinite, child: child),
    );
  }
}

/// Scales its child (typically a StatusBadge) down instead of overflowing
/// when a long localized label meets a very narrow card.
class FitBadge extends StatelessWidget {
  const FitBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

/// Text button in the error tone for destructive secondary actions.
class DangerTextButton extends StatelessWidget {
  const DangerTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.delete_outline,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}
