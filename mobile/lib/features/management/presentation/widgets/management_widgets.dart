import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../l10n/app_localizations.dart';

/// Localized text for an [ApiException] (mirrors the Angular error boxes).
String describeApiError(BuildContext context, Object? error) {
  final loc = AppLocalizations.of(context);
  if (error is ApiException) {
    if (error.isNetwork) return loc.commonNetworkError;
    if (error.isUnauthorized) return loc.commonUnauthorized;
    if (error.isBusiness && error.businessMessage != null) return error.businessMessage!;
    if (error.isServer && error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
    return loc.commonServerError;
  }
  return error is Exception ? loc.commonServerError : loc.commonServerError;
}

/// Small label/value row used by detail screens (dt/dd grid in Angular).
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.expanded = false});

  final String label;
  final String value;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: expanded ? double.infinity : 132,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (!expanded)
            Expanded(
              child: Text(value, style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }
}

/// Section heading inside a detail page.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

/// Taka amount with South-Asian (lakh) grouping: 1250000 -> "৳ 12,50,000".
String formatTaka(num value, {int decimals = 0}) {
  final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '৳ ', decimalDigits: decimals);
  return fmt.format(value);
}

String formatAmount(num value, {int decimals = 2}) {
  final fmt = NumberFormat.decimalPattern('en_IN')
    ..minimumFractionDigits = decimals
    ..maximumFractionDigits = decimals;
  return fmt.format(value);
}

/// Full-screen image preview dialog with error fallback.
Future<void> showImagePreview(BuildContext context, String url, String alt) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(title: Text(alt), actions: [
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
          ]),
          Flexible(
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    AppLocalizations.of(ctx).adminSubmissionDetailFileMissing,
                    textAlign: TextAlign.center,
                  ),
                ),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : const CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
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
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items,
      onChanged: onChanged,
    );
  }
}

/// Date field backed by showDatePicker (yyyy-MM-dd string values).
class DateField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value);
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        helperText: hint,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      onTap: () async {
        final initial = DateTime.tryParse(value) ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged(DateFormat('yyyy-MM-dd').format(picked));
        }
      },
    );
  }
}

/// A locally picked file ready for upload.
class UploadTarget {
  const UploadTarget({required this.path, required this.fileName});

  final String path;
  final String fileName;
}
