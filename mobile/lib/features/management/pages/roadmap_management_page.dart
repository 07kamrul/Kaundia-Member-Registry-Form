import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/finance_entities.dart';
import '../presentation/bloc/bloc_actions.dart';
import '../presentation/bloc/roadmap_bloc.dart';
import '../presentation/widgets/management_page_kit.dart';
import '../presentation/widgets/management_widgets.dart';

/// Roadmap management (Angular roadmap-management): per-timeframe item lists
/// with status chips, add/edit/delete, reorder, archive + history.
class RoadmapManagementPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const RoadmapManagementPage(
      {super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<RoadmapManagementPage> createState() => _RoadmapManagementPageState();
}

const _statuses = [
  RoadmapStatus.planned,
  RoadmapStatus.inProgress,
  RoadmapStatus.done,
];

String _statusLabel(AppLocalizations loc, RoadmapStatus status) =>
    switch (status) {
      RoadmapStatus.planned => loc.adminRoadmapStatusPlanned,
      RoadmapStatus.inProgress => loc.adminRoadmapStatusInProgress,
      RoadmapStatus.done => loc.adminRoadmapStatusDone,
      _ => '—',
    };

IconData _statusIcon(RoadmapStatus status) => switch (status) {
      RoadmapStatus.inProgress => Icons.autorenew_rounded,
      RoadmapStatus.done => Icons.check_circle_outline,
      _ => Icons.radio_button_unchecked,
    };

class _RoadmapManagementPageState extends State<RoadmapManagementPage> {
  bool _notifyOnDone = true;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) =>
          RoadmapBloc(repository: RoadmapRepository(apiClient: sl<ApiClient>()))
            ..add(const RoadmapLoadRequested()),
      child: BlocConsumer<RoadmapBloc, RoadmapState>(
        listenWhen: (a, b) =>
            a.actionError != b.actionError || a.archiveCount != b.archiveCount,
        listener: (context, state) {
          if (state.actionError != null) {
            showAppToast(context, describeApiError(context, state.actionError),
                error: true);
          }
          if (state.archiveCount != null) {
            showAppToast(
                context, loc.adminRoadmapArchiveDone(state.archiveCount!));
          }
        },
        builder: (context, state) => _buildScaffold(context, state),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, RoadmapState state) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<RoadmapBloc>();
    final roadmap = state.roadmap;
    return Scaffold(
      floatingActionButton: roadmap == null || roadmap.timeframes.isEmpty
          ? null
          : AddFab(
              label: loc.adminRoadmapAdd,
              onPressed: () => _openForm(context, bloc, roadmap),
            ),
      body: PageBody(
        padding: const EdgeInsets.only(bottom: kFabClearance),
        onRefresh: () => reloadAndWait<RoadmapEvent, RoadmapState>(
          bloc,
          const RoadmapLoadRequested(),
          (s) => s.loading,
        ),
        children: [
          PageHeader(
            icon: Icons.route_outlined,
            title: loc.adminRoadmapTitle,
            subtitle: loc.adminRoadmapSubtitle,
          ),
          if (state.loading && roadmap == null)
            const SkeletonLoader(lines: 6)
          else if (state.loadError != null)
            InlineError(
              message: loc.adminRoadmapErrorsGeneric,
              onRetry: () => bloc.add(const RoadmapLoadRequested()),
            )
          else if (roadmap == null)
            EmptyState(icon: Icons.route_outlined, message: loc.commonNoData)
          else ...[
            _overview(context, bloc, roadmap),
            ReloadingBar(visible: state.loading),
            CardGrid(
              minItemWidth: 360,
              children: [
                for (final tf in roadmap.timeframes)
                  _TimeframeCard(
                    timeframe: tf,
                    busyItemId: state.busyItemId,
                    onAdd: () => _openForm(context, bloc, roadmap, timeframeId: tf.id),
                    onStatus: (item, status) => bloc.add(RoadmapStatusSet(
                        item: item, status: status, notify: _notifyOnDone)),
                    onEdit: (item) => _openForm(context, bloc, roadmap, editing: item),
                    onDelete: (item) => _delete(context, bloc, item),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _overview(BuildContext context, RoadmapBloc bloc, Roadmap roadmap) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final totals = roadmap.totals;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.adminRoadmapOverall(totals.done, totals.total),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                '${totals.percent}%',
                style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          _ProgressBar(value: totals.total == 0 ? 0 : totals.done / totals.total),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(loc.adminRoadmapNotifyOnDone),
            value: _notifyOnDone,
            onChanged: (v) => setState(() => _notifyOnDone = v),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              AppButton(
                label: loc.adminRoadmapArchiveHistory,
                variant: AppButtonVariant.ghost,
                icon: Icons.history,
                onPressed: () => _openHistorySheet(context, bloc),
              ),
              AppButton(
                label: loc.adminRoadmapArchiveButton,
                variant: AppButtonVariant.secondary,
                icon: Icons.archive_outlined,
                onPressed: () => _openArchiveDialog(context, bloc),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, RoadmapBloc bloc, RoadmapItem item) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await confirmDialog(
      context,
      title: loc.adminRoadmapDeleteTitle,
      message: item.text,
      confirmLabel: loc.commonDelete,
      destructive: true,
    );
    if (confirmed && context.mounted) bloc.add(RoadmapItemDeleted(item: item));
  }

  Future<void> _openForm(BuildContext context, RoadmapBloc bloc, Roadmap roadmap,
      {RoadmapItem? editing, int? timeframeId}) {
    return showFormSheet<void>(
      context,
      builder: (_) => _RoadmapForm(
        bloc: bloc,
        roadmap: roadmap,
        editing: editing,
        initialTimeframeId: timeframeId,
        notify: _notifyOnDone,
      ),
    );
  }

  Future<void> _openArchiveDialog(BuildContext context, RoadmapBloc bloc) async {
    final onlyDone = await showDialog<bool>(
      context: context,
      builder: (_) => const _ArchiveDialog(),
    );
    if (onlyDone != null && context.mounted) {
      bloc.add(RoadmapArchived(onlyDone: onlyDone));
    }
  }

  void _openHistorySheet(BuildContext context, RoadmapBloc bloc) {
    bloc.add(const RoadmapHistoryLoadRequested());
    showFormSheet<void>(
      context,
      builder: (_) => BlocProvider.value(value: bloc, child: const _HistorySheet()),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 6),
    );
  }
}

class _TimeframeCard extends StatelessWidget {
  const _TimeframeCard({
    required this.timeframe,
    required this.busyItemId,
    required this.onAdd,
    required this.onStatus,
    required this.onEdit,
    required this.onDelete,
  });

  final RoadmapTimeframe timeframe;
  final int? busyItemId;
  final VoidCallback onAdd;
  final void Function(RoadmapItem item, RoadmapStatus status) onStatus;
  final ValueChanged<RoadmapItem> onEdit;
  final ValueChanged<RoadmapItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tf = timeframe;
    return AppCard(
      margin: EdgeInsets.zero,
      title: tf.nameBn,
      trailing: Text(
        '${tf.done}/${tf.total}',
        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tf.windowBn, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          _ProgressBar(value: tf.total == 0 ? 0 : tf.done / tf.total),
          const SizedBox(height: 8),
          if (tf.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(loc.commonNoData, style: theme.textTheme.bodySmall),
            ),
          for (var i = 0; i < tf.items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _ItemTile(
              timeframe: tf,
              item: tf.items[i],
              index: i,
              busy: busyItemId == tf.items[i].id || busyItemId == -1,
              onStatus: (s) => onStatus(tf.items[i], s),
              onEdit: () => onEdit(tf.items[i]),
              onDelete: () => onDelete(tf.items[i]),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: loc.adminRoadmapAddHere,
              variant: AppButtonVariant.ghost,
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.timeframe,
    required this.item,
    required this.index,
    required this.busy,
    required this.onStatus,
    required this.onEdit,
    required this.onDelete,
  });

  final RoadmapTimeframe timeframe;
  final RoadmapItem item;
  final int index;
  final bool busy;
  final ValueChanged<RoadmapStatus> onStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasDate = item.targetDate != null && item.targetDate!.isNotEmpty;
    final hasOwner = item.owner != null && item.owner!.isNotEmpty;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: busy ? 0.5 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(item.text, maxLines: 4, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium),
            if (hasDate || hasOwner)
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (hasDate) MetaText(icon: Icons.flag_outlined, text: item.targetDate!),
                  if (hasOwner) MetaText(icon: Icons.person_outline, text: item.owner!),
                ],
              ),
            Semantics(
              label: loc.adminRoadmapStatusAria,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final status in _statuses)
                    ChoiceChip(
                      avatar: Icon(_statusIcon(status), size: 16),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      label: Text(_statusLabel(loc, status)),
                      selected: item.status == status,
                      onSelected: busy || item.status == status
                          ? null
                          : (_) => onStatus(status),
                    ),
                ],
              ),
            ),
            _ItemActions(
              timeframe: timeframe,
              item: item,
              index: index,
              busy: busy,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemActions extends StatelessWidget {
  const _ItemActions({
    required this.timeframe,
    required this.item,
    required this.index,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final RoadmapTimeframe timeframe;
  final RoadmapItem item;
  final int index;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<RoadmapBloc>();
    final last = timeframe.items.length - 1;
    void move(int delta) => bloc.add(
        RoadmapItemsReordered(timeframe: timeframe, index: index, delta: delta));
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: loc.adminRoadmapMoveUp,
          icon: const Icon(Icons.arrow_upward_rounded, size: 20),
          onPressed: busy || index == 0 ? null : () => move(-1),
        ),
        IconButton(
          tooltip: loc.adminRoadmapMoveDown,
          icon: const Icon(Icons.arrow_downward_rounded, size: 20),
          onPressed: busy || index == last ? null : () => move(1),
        ),
        IconButton(
          tooltip: loc.commonEdit,
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: busy ? null : onEdit,
        ),
        IconButton(
          tooltip: loc.commonDelete,
          color: Theme.of(context).colorScheme.error,
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: busy ? null : onDelete,
        ),
      ],
    );
  }
}

class _RoadmapForm extends StatefulWidget {
  const _RoadmapForm({
    required this.bloc,
    required this.roadmap,
    required this.notify,
    this.editing,
    this.initialTimeframeId,
  });

  final RoadmapBloc bloc;
  final Roadmap roadmap;
  final bool notify;
  final RoadmapItem? editing;
  final int? initialTimeframeId;

  @override
  State<_RoadmapForm> createState() => _RoadmapFormState();
}

class _RoadmapFormState extends State<_RoadmapForm> {
  late final _text = TextEditingController(text: widget.editing?.text ?? '');
  late final _owner = TextEditingController(text: widget.editing?.owner ?? '');
  late final _note = TextEditingController(text: widget.editing?.note ?? '');
  late int _timeframeId = widget.editing?.timeframeId ??
      widget.initialTimeframeId ??
      widget.roadmap.timeframes.first.id;
  late RoadmapStatus _status = widget.editing?.status ?? RoadmapStatus.planned;
  late String _targetDate = widget.editing?.targetDate ?? '';
  bool _saving = false;
  String? _textError;

  @override
  void dispose() {
    _text.dispose();
    _owner.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final editing = widget.editing;
    final moved = editing != null && editing.timeframeId != _timeframeId;
    return FormSheet(
      icon: Icons.route_outlined,
      title: editing == null ? loc.adminRoadmapFormCreateTitle : loc.adminRoadmapFormEditTitle,
      actions: [
        AppButton(label: loc.commonSave, loading: _saving, onPressed: _save),
      ],
      children: [
        LabeledDropdown<int>(
          label: loc.adminRoadmapFormTimeframe,
          value: _timeframeId,
          prefixIcon: Icons.date_range_outlined,
          options: [for (final tf in widget.roadmap.timeframes) (tf.id, tf.nameBn)],
          onChanged: (v) => setState(() => _timeframeId = v ?? _timeframeId),
        ),
        if (moved)
          Text(loc.adminRoadmapFormMoveHint, style: Theme.of(context).textTheme.bodySmall),
        TextField(
          controller: _text,
          maxLength: roadmapTextMax,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {
            if (_textError != null) setState(() => _textError = null);
          },
          decoration: InputDecoration(labelText: loc.adminRoadmapFormText, errorText: _textError),
        ),
        if (editing == null) _statusPicker(loc),
        DateField(
          label: loc.adminRoadmapFormTargetDate,
          value: _targetDate,
          onChanged: (v) => setState(() => _targetDate = v),
        ),
        TextField(
          controller: _owner,
          maxLength: roadmapOwnerMax,
          decoration: InputDecoration(
            labelText: loc.adminRoadmapFormOwner,
            hintText: loc.adminRoadmapFormOwnerPlaceholder,
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        TextField(
          controller: _note,
          maxLength: roadmapNoteMax,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: loc.adminRoadmapFormNote,
            hintText: loc.adminRoadmapFormNotePlaceholder,
          ),
        ),
      ],
    );
  }

  Widget _statusPicker(AppLocalizations loc) {
    return InputDecorator(
      decoration: InputDecoration(labelText: loc.adminRoadmapFormStatus),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in _statuses)
            ChoiceChip(
              avatar: Icon(_statusIcon(option), size: 16),
              showCheckmark: false,
              label: Text(_statusLabel(loc, option)),
              selected: _status == option,
              onSelected: (_) => setState(() => _status = option),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _textError = loc.adminRoadmapErrorsTextRequired);
      return;
    }
    setState(() => _saving = true);
    final editing = widget.editing;
    final ok = editing == null
        ? await dispatchForBool(
            widget.bloc,
            (c) => RoadmapItemCreated(
                completer: c,
                timeframeId: _timeframeId,
                text: text,
                status: _status,
                targetDate: _targetDate.isEmpty ? null : _targetDate,
                owner: _owner.text.trim(),
                note: _note.text.trim(),
                notify: widget.notify))
        : await dispatchForBool(
            widget.bloc,
            (c) => RoadmapItemUpdated(
                completer: c,
                item: editing,
                text: text,
                timeframeId: _timeframeId,
                targetDate: _targetDate,
                owner: _owner.text.trim(),
                note: _note.text.trim()));
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }
}

/// Returns `onlyDone` when confirmed, null when cancelled.
class _ArchiveDialog extends StatefulWidget {
  const _ArchiveDialog();

  @override
  State<_ArchiveDialog> createState() => _ArchiveDialogState();
}

class _ArchiveDialogState extends State<_ArchiveDialog> {
  bool _onlyDone = true;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.archive_outlined),
      title: Text(loc.adminRoadmapArchiveTitle),
      content: DialogBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(loc.adminRoadmapArchiveMessage),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _onlyDone,
              title: Text(loc.adminRoadmapArchiveOnlyDone),
              onChanged: (v) => setState(() => _onlyDone = v ?? true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_onlyDone),
          child: Text(loc.adminRoadmapArchiveConfirm),
        ),
      ],
    );
  }
}

class _HistorySheet extends StatelessWidget {
  const _HistorySheet();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<RoadmapBloc, RoadmapState>(
      builder: (context, state) {
        final history = state.history;
        return FormSheet(
          icon: Icons.history,
          title: loc.adminRoadmapArchiveHistory,
          children: [
            if (history == null)
              const LinearProgressIndicator()
            else if (history.isEmpty)
              EmptyState(icon: Icons.archive_outlined, message: loc.adminRoadmapArchiveEmpty)
            else
              for (final cycle in history) _CycleCard(cycle: cycle),
          ],
        );
      },
    );
  }
}

class _CycleCard extends StatelessWidget {
  const _CycleCard({required this.cycle});

  final RoadmapArchivedCycle cycle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = cycle.archivedAt.length >= 10
        ? cycle.archivedAt.substring(0, 10)
        : cycle.archivedAt;
    return AppCard(
      margin: EdgeInsets.zero,
      title: date,
      trailing: Text(loc.adminRoadmapArchiveCycleSummary(cycle.done, cycle.total),
          style: theme.textTheme.bodySmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in cycle.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _statusIcon(item.status),
                    size: 18,
                    color: item.status == RoadmapStatus.done
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.text, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
