import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/admin_entities.dart';
import 'management_widgets.dart';

/// One config list entry: value, inline-editable label, reorder + active
/// toggle. Null callbacks render the control disabled.
class ConfigListItemCard extends StatelessWidget {
  const ConfigListItemCard({
    super.key,
    required this.item,
    required this.canManage,
    required this.busy,
    required this.editing,
    required this.editController,
    required this.onEditStart,
    required this.onEditSave,
    required this.onEditCancel,
    required this.onToggle,
    this.onMoveUp,
    this.onMoveDown,
  });

  final ConfigListItem item;
  final bool canManage;
  final bool busy;
  final bool editing;
  final TextEditingController editController;
  final VoidCallback onEditStart;
  final ValueChanged<String> onEditSave;
  final VoidCallback onEditCancel;
  final VoidCallback onToggle;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ManagementRecordCard(
      title: item.value,
      badge: StatusBadge(
        kind: item.isActive ? StatusKind.approved : StatusKind.neutral,
        label: item.isActive
            ? loc.adminConfigListsActive
            : loc.adminConfigListsInactive,
      ),
      actions: _actions(loc),
      children: [editing ? _editor(loc) : _label(context, loc)],
    );
  }

  Widget _label(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: canManage ? onEditStart : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(item.label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium),
            ),
            if (canManage)
              Tooltip(
                message: loc.adminConfigListsActionsEditLabel,
                child: Icon(Icons.edit_outlined,
                    size: 18, color: theme.colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _editor(AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: editController,
            autofocus: true,
            enabled: !busy,
            decoration:
                InputDecoration(labelText: loc.adminConfigListsFormLabel),
            onFieldSubmitted: onEditSave,
          ),
        ),
        IconButton(
          tooltip: loc.adminConfigListsActionsSave,
          icon: const Icon(Icons.check),
          onPressed: busy ? null : () => onEditSave(editController.text),
        ),
        IconButton(
          tooltip: loc.adminConfigListsActionsCancel,
          icon: const Icon(Icons.close),
          onPressed: busy ? null : onEditCancel,
        ),
      ],
    );
  }

  List<Widget> _actions(AppLocalizations loc) {
    return [
      if (busy)
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      IconButton(
        tooltip: loc.adminConfigListsActionsMoveUp,
        icon: const Icon(Icons.arrow_upward),
        onPressed: onMoveUp,
      ),
      IconButton(
        tooltip: loc.adminConfigListsActionsMoveDown,
        icon: const Icon(Icons.arrow_downward),
        onPressed: onMoveDown,
      ),
      if (canManage)
        Tooltip(
          message: item.isActive
              ? loc.adminConfigListsDeactivate
              : loc.adminConfigListsActivate,
          child: Switch(
            value: item.isActive,
            onChanged: busy ? null : (_) => onToggle(),
          ),
        ),
    ];
  }
}
