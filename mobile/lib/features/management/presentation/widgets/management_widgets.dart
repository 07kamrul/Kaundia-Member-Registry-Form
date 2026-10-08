import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';

export 'management_record_widgets.dart';

/// Max width of management dialogs so they never stretch across tablets.
const double _dialogMaxWidth = 480;

/// Pull-to-refresh gives up waiting after this long (the bloc still reports
/// its own errors).
const Duration _refreshTimeout = Duration(seconds: 20);

/// Localized text for an [ApiException] (mirrors the Angular error boxes).
String describeApiError(BuildContext context, Object? error) {
  final loc = AppLocalizations.of(context);
  if (error is ApiException) {
    if (error.isNetwork) return loc.commonNetworkError;
    if (error.isUnauthorized) return loc.commonUnauthorized;
    if (error.isBusiness && error.businessMessage != null) {
      return error.businessMessage!;
    }
    if (error.isServer && error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
    return loc.commonServerError;
  }
  return error is Exception ? loc.commonServerError : loc.commonServerError;
}

/// Pull-to-refresh helper: dispatches [event] and completes once [isLoading]
/// reports the reload finished, so the [RefreshIndicator] spinner tracks the
/// real request.
Future<void> reloadAndWait<E, S>(
  Bloc<E, S> bloc,
  E event,
  bool Function(S state) isLoading,
) async {
  final finished =
      bloc.stream.firstWhere((s) => !isLoading(s)).timeout(_refreshTimeout);
  bloc.add(event);
  try {
    await finished;
  } on TimeoutException {
    // Slow network: stop the spinner; the bloc surfaces its own outcome.
  } on StateError {
    // The bloc closed (page left) before the reload finished.
  }
}

/// Small label/value row used by detail screens (dt/dd grid in Angular).
/// [expanded] stacks the label above the value for long text (addresses).
class InfoRow extends StatelessWidget {
  const InfoRow(
      {super.key,
      required this.label,
      required this.value,
      this.expanded = false});

  final String label;
  final String value;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelText = Text(
      label,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final valueText = Text(
      value.trim().isEmpty ? '—' : value,
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: expanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelText, const SizedBox(height: 2), valueText],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: labelText),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: valueText),
              ],
            ),
    );
  }
}

/// Section heading inside a detail page: gold accent bar + emerald title.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Taka amount with South-Asian (lakh) grouping: 1250000 -> "৳ 12,50,000".
String formatTaka(num value, {int decimals = 0}) {
  final fmt = NumberFormat.currency(
      locale: 'en_IN', symbol: '৳ ', decimalDigits: decimals);
  return fmt.format(value);
}

String formatAmount(num value, {int decimals = 2}) {
  final fmt = NumberFormat.decimalPattern('en_IN')
    ..minimumFractionDigits = decimals
    ..maximumFractionDigits = decimals;
  return fmt.format(value);
}

/// Full-screen image preview dialog (zoomable) with error fallback.
Future<void> showImagePreview(BuildContext context, String url, String alt) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ImagePreviewDialog(url: url, alt: alt),
  );
}

class _ImagePreviewDialog extends StatelessWidget {
  const _ImagePreviewDialog({required this.url, required this.alt});

  final String url;
  final String alt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Dialog(
      insetPadding: EdgeInsets.all(context.isCompact ? 12 : 32),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 960,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(alt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium),
                  ),
                  IconButton(
                    tooltip: loc.commonClose,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: InteractiveViewer(
                maxScale: 5,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _PreviewMissing(
                      message: loc.adminSubmissionDetailFileMissing),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          height: 240,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewMissing extends StatelessWidget {
  const _PreviewMissing({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 40, color: muted),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Single-select dropdown field with label.
class SelectField<T> extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    );
  }
}

/// Date field backed by showDatePicker (yyyy-MM-dd string values).
class DateField extends StatefulWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(DateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final initial = DateTime.tryParse(widget.value) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      widget.onChanged(DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.hint,
        suffixIcon: const Icon(Icons.event_outlined),
      ),
      onTap: _pick,
    );
  }
}

/// A locally picked file ready for upload.
class UploadTarget {
  const UploadTarget({required this.path, required this.fileName});

  final String path;
  final String fileName;
}

/// Same look as AppDialog.confirm but returns the result (AppDialog.confirm
/// is typed `Future<void>`, pages need the boolean).
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) {
  final loc = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        child: Text(message),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel ?? loc.commonCancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error)
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel ?? loc.commonConfirmAction),
        ),
      ],
    ),
  ).then((value) => value == true);
}

/// Asks for a free-text reason (reject / cancel flows). Returns the trimmed
/// text, or null when dismissed. [validator] errors are shown inline and keep
/// the dialog open.
Future<String?> showReasonDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? label,
  String? hint,
  String? summary,
  String? cancelLabel,
  int maxLength = 500,
  String? Function(String text)? validator,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(
      title: title,
      confirmLabel: confirmLabel,
      label: label,
      hint: hint,
      summary: summary,
      cancelLabel: cancelLabel,
      maxLength: maxLength,
      validator: validator,
    ),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.confirmLabel,
    required this.maxLength,
    this.label,
    this.hint,
    this.summary,
    this.cancelLabel,
    this.validator,
  });

  final String title;
  final String confirmLabel;
  final String? label;
  final String? hint;
  final String? summary;
  final String? cancelLabel;
  final int maxLength;
  final String? Function(String text)? validator;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    final error = widget.validator?.call(text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: theme.textTheme.titleLarge),
              if (widget.summary != null) ...[
                const SizedBox(height: 8),
                Text(widget.summary!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                maxLength: widget.maxLength,
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
                  errorText: _error,
                  alignLabelWithHint: true,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(widget.cancelLabel ?? loc.commonCancel),
                  ),
                  AppButton(
                    label: widget.confirmLabel,
                    variant: AppButtonVariant.danger,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
