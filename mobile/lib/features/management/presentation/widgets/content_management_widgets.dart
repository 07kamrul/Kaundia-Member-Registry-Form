import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/admin_entities.dart';
import 'management_page_kit.dart';
import 'management_widgets.dart';

/// Pieces shared by the notices and events management pages: published /
/// draft filter, list card and date + time fields.

/// Status filter chips + category dropdown, wrapping on narrow screens.
class ContentFilterBar extends StatelessWidget {
  const ContentFilterBar({
    super.key,
    required this.statusLabels,
    required this.publishedFilter,
    required this.onStatusChanged,
    required this.categoryLabel,
    required this.allCategoriesLabel,
    required this.categories,
    required this.categoryFilter,
    required this.onCategoryChanged,
  });

  /// All / published / draft.
  final List<String> statusLabels;
  final bool? publishedFilter;

  /// Receives the tab index the blocs expect (0 all, 1 published, 2 draft).
  final ValueChanged<int> onStatusChanged;
  final String categoryLabel;
  final String allCategoriesLabel;
  final List<ConfigListItem> categories;
  final String? categoryFilter;
  final ValueChanged<String?> onCategoryChanged;

  int get _selectedIndex => switch (publishedFilter) {
        null => 0,
        true => 1,
        false => 2,
      };

  @override
  Widget build(BuildContext context) {
    return FilterPanel(
      minFieldWidth: 260,
      fields: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < statusLabels.length; i++)
                ChoiceChip(
                  label: Text(statusLabels[i]),
                  selected: _selectedIndex == i,
                  onSelected: (_) => onStatusChanged(i),
                ),
            ],
          ),
        ),
        LabeledDropdown<String>(
          label: categoryLabel,
          value: categoryFilter,
          prefixIcon: Icons.sell_outlined,
          options: [
            (null, allCategoriesLabel),
            for (final c in categories) (c.id, c.label),
          ],
          onChanged: onCategoryChanged,
        ),
      ],
    );
  }
}

/// Category label lookup shared by both pages.
String contentCategoryLabel(List<ConfigListItem> categories, String? id) {
  if (id == null) return '—';
  for (final c in categories) {
    if (c.id == id) return c.label;
  }
  return '—';
}

/// Notice / event list card with publish toggle, edit and delete.
class ContentItemCard extends StatelessWidget {
  const ContentItemCard({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.published,
    required this.metas,
    required this.publishLabel,
    required this.busy,
    required this.onTogglePublish,
    required this.onEdit,
    required this.onDelete,
    this.preview,
    this.membersOnlyLabel,
  });

  final String title;
  final String? preview;
  final String statusLabel;
  final bool published;
  final List<(IconData, String)> metas;

  /// Shown as a badge when the item is members-only.
  final String? membersOnlyLabel;
  final String publishLabel;
  final bool busy;
  final VoidCallback onTogglePublish;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (preview != null && preview!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  preview!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FitBadge(
                    child: StatusBadge(
                      kind: published ? StatusKind.approved : StatusKind.neutral,
                      label: statusLabel,
                    ),
                  ),
                  for (final (icon, text) in metas) MetaText(icon: icon, text: text),
                  if (membersOnlyLabel != null)
                    FitBadge(
                      child: StatusBadge(kind: StatusKind.pending, label: membersOnlyLabel),
                    ),
                ],
              ),
              const Divider(height: 20),
              _actions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        DangerTextButton(label: loc.commonDelete, onPressed: busy ? null : onDelete),
        AppButton(
          label: loc.commonEdit,
          variant: AppButtonVariant.ghost,
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),
        AppButton(
          label: publishLabel,
          variant: AppButtonVariant.secondary,
          icon: published ? Icons.visibility_off_outlined : Icons.publish_rounded,
          loading: busy,
          onPressed: onTogglePublish,
        ),
      ],
    );
  }
}

/// Read-only time field backed by the Material time picker; values are
/// always 24-hour "HH:mm" so they round-trip through `isoFromParts`.
class TimeField extends StatefulWidget {
  const TimeField({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<TimeField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(TimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TimeOfDay? _parse(String text) {
    final parts = text.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _pick() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _parse(widget.value) ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    String two(int n) => n.toString().padLeft(2, '0');
    widget.onChanged('${two(picked.hour)}:${two(picked.minute)}');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      readOnly: true,
      onTap: _pick,
      decoration: InputDecoration(
        labelText: MaterialLocalizations.of(context).timePickerDialHelpText,
        hintText: 'HH:mm',
        suffixIcon: const Icon(Icons.schedule_rounded),
      ),
    );
  }
}

/// Date + time pair that stacks on narrow phones.
class DateTimeFields extends StatelessWidget {
  const DateTimeFields({
    super.key,
    required this.label,
    required this.date,
    required this.time,
    required this.onDateChanged,
    required this.onTimeChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final String date;
  final String time;
  final ValueChanged<String> onDateChanged;
  final ValueChanged<String> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    return FieldPair(
      first: DateField(label: label, hint: hint, value: date, onChanged: onDateChanged),
      second: TimeField(value: time, onChanged: onTimeChanged),
    );
  }
}

/// Empty list state with a "create first" call to action.
class ContentEmptyState extends StatelessWidget {
  const ContentEmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.helper,
    required this.actionLabel,
    required this.onCreate,
  });

  final IconData icon;
  final String message;
  final String helper;
  final String actionLabel;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      message: '$message\n$helper',
      action: AppButton(label: actionLabel, icon: Icons.add, onPressed: onCreate),
    );
  }
}
