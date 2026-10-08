import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

/// Small form primitives for the registration wizard. All user-visible strings
/// come from ARB via [AppLocalizations]; widgets dispatch changes upward and
/// hold no business logic.

class RegLabel extends StatelessWidget {
  const RegLabel({super.key, required this.text, this.required = false, this.error, this.child});

  final String text;
  final bool required;
  final String? error;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            children: [
              TextSpan(text: text),
              if (required)
                const TextSpan(text: ' *', style: TextStyle(color: AppColors.red600)),
            ],
          ),
        ),
        if (child != null) child!,
        if (error != null && error!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              error!,
              style: const TextStyle(color: AppColors.red600, fontSize: 12),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            children: [
              TextSpan(text: widget.label),
              if (widget.required)
                const TextSpan(text: ' *', style: TextStyle(color: AppColors.red600)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          readOnly: widget.readOnly,
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hint,
            errorText: (widget.error?.isNotEmpty ?? false) ? widget.error : null,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

/// Read-only amount field (admission fee / subscription) — the values always
/// come from the live fee settings, never user input.
class RegReadOnlyAmountField extends StatelessWidget {
  const RegReadOnlyAmountField({super.key, required this.label, required this.text, required this.hint});

  final String label;
  final String text;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RegLabel(required: true, text: label),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: text),
          readOnly: true,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 4),
        Text(hint, style: Theme.of(context).textTheme.bodySmall),
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
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            children: [
              TextSpan(text: label),
              if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.red600)),
            ],
          ),
        ),
        const SizedBox(height: 4),
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
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            errorText: (error?.isNotEmpty ?? false) ? error : null,
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
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
          ],
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
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

/// Section title inside a step.
class RegSectionTitle extends StatelessWidget {
  const RegSectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.red600.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.red600),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in messages)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• $m', style: const TextStyle(color: AppColors.red600, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
