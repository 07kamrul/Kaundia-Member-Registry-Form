import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/theme/app_theme.dart';

/// Small UI building blocks shared by the member pages. Everything here is
/// presentation-only; no page logic lives in this file.

/// Horizontal page gutter wrapper so non-card content lines up with [AppCard]s.
class Gutter extends StatelessWidget {
  const Gutter({super.key, required this.child, this.vertical = 0});

  final Widget child;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: vertical),
      child: child,
    );
  }
}

/// Lays form fields out one per row on phones and two per row once there is
/// room (>= 560 logical px), keeping each field's natural height.
class FieldGrid extends StatelessWidget {
  const FieldGrid({super.key, required this.children, this.minFieldWidth = 260});

  final List<Widget> children;
  final double minFieldWidth;

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      minItemWidth: minFieldWidth,
      maxColumns: 2,
      spacing: 12,
      children: children,
    );
  }
}

enum NoticeTone { info, success, warning, error }

/// Tinted inline banner with a leading icon — used for notices, warnings and
/// non-blocking errors inside a page.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.message,
    this.tone = NoticeTone.info,
    this.icon,
    this.action,
    this.margin,
  });

  final String message;
  final NoticeTone tone;
  final IconData? icon;
  final Widget? action;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color fg, IconData defaultIcon) = switch (tone) {
      NoticeTone.info => (scheme.primary, Icons.info_outline),
      NoticeTone.success => (AppColors.emerald600, Icons.check_circle_outline),
      NoticeTone.warning => (AppColors.goldStrong, Icons.warning_amber_rounded),
      NoticeTone.error => (scheme.error, Icons.error_outline),
    };
    final ink = Theme.of(context).brightness == Brightness.dark && tone != NoticeTone.error
        ? scheme.onSurface
        : fg;
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ink)),
                if (action != null) Align(alignment: Alignment.centerLeft, child: action!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded tinted square holding an icon; the leading visual of list rows.
class LeadingIcon extends StatelessWidget {
  const LeadingIcon({super.key, required this.icon, this.color, this.size = 40});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
      ),
      child: Icon(icon, color: tint, size: size * 0.5),
    );
  }
}

/// Left-aligned "+ Add …" text button placed under a card's list. Kept out of
/// the card header because long Bangla labels don't fit beside the title on
/// phones.
class AddItemButton extends StatelessWidget {
  const AddItemButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

/// Muted icon + text pair for secondary metadata (dates, counts, people).
/// Use inside a [Wrap] so items flow onto new lines on narrow screens.
class MetaChip extends StatelessWidget {
  const MetaChip({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: muted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}

/// Previous / "page x of y" / next control used under paginated lists.
class PagerBar extends StatelessWidget {
  const PagerBar({
    super.key,
    required this.label,
    required this.previousTooltip,
    required this.nextTooltip,
    this.onPrevious,
    this.onNext,
  });

  final String label;
  final String previousTooltip;
  final String nextTooltip;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Gutter(
      vertical: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.outlined(
            tooltip: previousTooltip,
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          IconButton.outlined(
            tooltip: nextTooltip,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

/// Text field that owns its controller and only overwrites the text when the
/// external [value] really changed (e.g. after a server load). Avoids the
/// cursor jumping that a fresh controller per build causes.
class SyncedTextField extends StatefulWidget {
  const SyncedTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.icon,
    this.errorText,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.onSubmitted,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? label;
  final String? hint;
  final IconData? icon;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<SyncedTextField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant SyncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiline = widget.maxLines > 1;
    return TextField(
      controller: _controller,
      minLines: multiline ? 2 : 1,
      maxLines: widget.maxLines,
      keyboardType: multiline ? TextInputType.multiline : widget.keyboardType,
      textInputAction: multiline ? TextInputAction.newline : widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        errorMaxLines: 3,
        alignLabelWithHint: multiline,
        prefixIcon: widget.icon == null ? null : Icon(widget.icon),
      ),
    );
  }
}

/// Read-only field that opens a date picker and reports `yyyy-MM-dd`.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onPicked,
    this.firstDate,
    this.lastDate,
    this.icon = Icons.event_outlined,
  });

  final String label;
  final String value;
  final ValueChanged<String> onPicked;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final IconData icon;

  Future<void> _pick(BuildContext context) async {
    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime(2100);
    var initial = DateTime.tryParse(value) ?? DateTime.now();
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDate: initial,
    );
    if (picked != null) onPicked(picked.toIso8601String().substring(0, 10));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => _pick(context),
      child: InputDecorator(
        isEmpty: value.isEmpty,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Fires [trigger] and completes once the bloc emits a state that satisfies
/// [isSettled]. Backs pull-to-refresh so the spinner tracks the real reload.
Future<void> reloadAndWait<S>(
  BlocBase<S> bloc,
  VoidCallback trigger,
  bool Function(S state) isSettled,
) async {
  final settled = bloc.stream.firstWhere(isSettled);
  trigger();
  try {
    await settled.timeout(const Duration(seconds: 30));
  } on TimeoutException {
    return;
  } on StateError {
    return;
  }
}
