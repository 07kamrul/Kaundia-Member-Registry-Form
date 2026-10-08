import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

/// Small form primitives for the registration wizard. All user-visible strings
/// come from ARB via [AppLocalizations]; widgets dispatch changes upward and
/// hold no business logic.

/// Field label with an optional required marker. Uses [Text.rich] so it
/// honours the system text scale.
class _LabelText extends StatelessWidget {
  const _LabelText({required this.text, required this.required});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text),
          if (required) TextSpan(text: ' *', style: TextStyle(color: theme.colorScheme.error)),
        ],
      ),
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class RegLabel extends StatelessWidget {
  const RegLabel({super.key, required this.text, this.required = false, this.error, this.child});

  final String text;
  final bool required;
  final String? error;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _LabelText(text: text, required: required),
        if (child != null) child!,
        if (error != null && error!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}

/// Text field whose controller re-seeds when the bloc-driven value changes
/// externally (draft restore, same-as-current copy, programmatic clears).
class RegTextField extends StatefulWidget {
  const RegTextField({
    super.key,
    required this.label,
    this.value = '',
    required this.onChanged,
    this.required = false,
    this.error,
    this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.readOnly = false,
    this.prefixIcon,
    this.autofillHints,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool required;
  final String? error;
  final String? hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final bool readOnly;
  final IconData? prefixIcon;
  final Iterable<String>? autofillHints;

  /// Defaults to "next" for single-line fields so the keyboard walks the form.
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  @override
  State<RegTextField> createState() => _RegTextFieldState();
}

class _RegTextFieldState extends State<RegTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant RegTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text && widget.value != oldWidget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.error?.isNotEmpty ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _LabelText(text: widget.label, required: widget.required),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          readOnly: widget.readOnly,
          autofillHints: widget.readOnly ? null : widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          textInputAction: widget.textInputAction ??
              (widget.maxLines == 1 ? TextInputAction.next : TextInputAction.newline),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hint,
            errorText: hasError ? widget.error : null,
            errorMaxLines: 3,
            filled: true,
            fillColor: widget.readOnly ? theme.colorScheme.surfaceContainerHighest : null,
            prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }
}

/// Read-only amount field (admission fee / subscription) — the values always
/// come from the live fee settings, never user input.
class RegReadOnlyAmountField extends StatefulWidget {
  const RegReadOnlyAmountField({
    super.key,
    required this.label,
    required this.text,
    required this.hint,
  });

  final String label;
  final String text;
  final String hint;

  @override
  State<RegReadOnlyAmountField> createState() => _RegReadOnlyAmountFieldState();
}

class _RegReadOnlyAmountFieldState extends State<RegReadOnlyAmountField> {
  late final TextEditingController _controller = TextEditingController(text: widget.text);

  @override
  void didUpdateWidget(covariant RegReadOnlyAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _controller.text) _controller.text = widget.text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RegLabel(required: true, text: widget.label),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          readOnly: true,
          enableInteractiveSelection: false,
          style: theme.textTheme.titleMedium,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            prefixText: '৳ ',
            suffixIcon:
                Icon(Icons.lock_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        if (widget.hint.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(widget.hint, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

class RegDropdown extends StatelessWidget {
  const RegDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.required = false,
    this.error,
    this.itemLabel,
    this.enabled = true,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool required;
  final String? error;
  final String Function(String item)? itemLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _LabelText(text: label, required: required),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? null : value,
          items: [
            DropdownMenuItem<String>(
              enabled: false,
              child: Text(l10n.registrationAddressInfoSelectPlaceholder),
            ),
            for (final item in items)
              DropdownMenuItem<String>(
                value: item,
                child: Text(itemLabel?.call(item) ?? item, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
          menuMaxHeight: 420,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            errorText: (error?.isNotEmpty ?? false) ? error : null,
            errorMaxLines: 3,
          ),
        ),
      ],
    );
  }
}

/// White-fill/black-check checkbox matching AppCheckbox visuals but with a
/// label row + optional error text.
class RegCheckboxRow extends StatelessWidget {
  const RegCheckboxRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(label)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegRadioRow<T> extends StatelessWidget {
  const RegRadioRow({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final selected = groupValue == value;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                // White fill keeps the black ring visible in dark mode too.
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(label)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Section title inside a step: gold accent bar + primary heading.
class RegSectionTitle extends StatelessWidget {
  const RegSectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 20,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bordered surface grouping a block of fields inside a step. Lives inside
/// the page gutter, so it carries no horizontal margin of its own.
class RegSectionCard extends StatelessWidget {
  const RegSectionCard({super.key, required this.child, this.title, this.icon, this.trailing});

  final Widget child;
  final String? title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Two fields side by side when there is room, stacked otherwise.
class RegFieldPair extends StatelessWidget {
  const RegFieldPair({super.key, required this.first, required this.second, this.minWidth = 520});

  final Widget first;
  final Widget second;

  /// Below this width the pair stacks vertically.
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minWidth) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 16),
              Expanded(child: second),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 12), second],
        );
      },
    );
  }
}

/// Attached-file chip with a remove action, or nothing when [fileName] is empty.
class RegFileChip extends StatelessWidget {
  const RegFileChip({
    super.key,
    required this.fileName,
    required this.removeLabel,
    required this.onRemove,
  });

  final String fileName;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
          IconButton(
            tooltip: removeLabel,
            icon: Icon(Icons.close, size: 18, color: theme.colorScheme.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Red error box listing validation messages (Angular .error-box).
class RegErrorBox extends StatelessWidget {
  const RegErrorBox({super.key, required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final color = theme.colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in messages)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• $m',
                      style: theme.textTheme.bodySmall?.copyWith(color: color, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
