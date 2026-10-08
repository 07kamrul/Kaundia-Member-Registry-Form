import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/finance_entities.dart';
import '../presentation/bloc/bloc_actions.dart';
import '../presentation/bloc/roadmap_bloc.dart';
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

class _RoadmapManagementPageState extends State<RoadmapManagementPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) =>
          RoadmapBloc(repository: RoadmapRepository(apiClient: sl<ApiClient>()))
            ..add(const RoadmapLoadRequested()),
      child: BlocConsumer<RoadmapBloc, RoadmapState>(
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
        builder: (context, state) {
          final bloc = context.read<RoadmapBloc>();
          final roadmap = state.roadmap;
          return ListView(
            children: [
              PageHeader(
                  title: loc.adminRoadmapTitle,
                  subtitle: loc.adminRoadmapSubtitle),
              if (state.loading)
                const SkeletonLoader(lines: 6)
              else if (state.loadError != null)
                InlineError(
                    message: loc.adminRoadmapErrorsGeneric,
                    onRetry: () => bloc.add(const RoadmapLoadRequested()))
              else if (roadmap == null)
                EmptyState(message: loc.commonNoData)
              else ...[
                // Overall progress.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('${loc.adminRoadmapOverall}: '),
                      Text(
                        '${roadmap.totals.done}/${roadmap.totals.total} (${roadmap.totals.percent}%)',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      AppButton(
                        label: loc.adminRoadmapAdd,
                        icon: Icons.add,
                        onPressed: () => _openForm(context, loc, bloc, roadmap),
                      ),
                      AppButton(
                        label: loc.adminRoadmapArchiveButton,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _openArchiveDialog(context, loc, bloc),
                      ),
                      AppButton(
                        label: loc.adminRoadmapArchiveHistory,
                        variant: AppButtonVariant.ghost,
                        onPressed: () {
                          bloc.add(const RoadmapHistoryLoadRequested());
                          _openHistorySheet(context, loc, bloc);
                        },
                      ),
                    ],
                  ),
                ),
                // Notify toggle.
                SwitchListTile(
                  title: Text(loc.adminRoadmapNotifyOnDone),
                  value: _notifyOnDone,
                  onChanged: (v) => setState(() => _notifyOnDone = v),
                ),
                // Timeframes with items.
                for (final tf in roadmap.timeframes)
                  AppCard(
                    title: '${tf.nameBn} (${tf.windowBn})',
                    trailing: Text('${tf.done}/${tf.total}'),
                    child: Column(
                      children: [
                        if (tf.items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(loc.commonNoData),
                          ),
                        for (var i = 0; i < tf.items.length; i++)
                          _itemTile(
                              context, loc, bloc, roadmap, tf, tf.items[i], i),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  bool _notifyOnDone = true;

  String _statusLabel(AppLocalizations loc, RoadmapStatus status) =>
      switch (status) {
        RoadmapStatus.planned => loc.adminRoadmapStatusPlanned,
        RoadmapStatus.inProgress => loc.adminRoadmapStatusInProgress,
        RoadmapStatus.done => loc.adminRoadmapStatusDone,
        _ => '—',
      };

  Widget _itemTile(BuildContext context, AppLocalizations loc, RoadmapBloc bloc,
      Roadmap roadmap, RoadmapTimeframe tf, RoadmapItem item, int index) {
    final busy =
        bloc.state.busyItemId == item.id || bloc.state.busyItemId == -1;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.text),
                  if (item.targetDate != null && item.targetDate!.isNotEmpty)
                    Text(item.targetDate!,
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            // Status segmented chips.
            for (final status in const [
              RoadmapStatus.planned,
              RoadmapStatus.inProgress,
              RoadmapStatus.done,
            ])
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ChoiceChip(
                  label: Text(_statusLabel(loc, status)),
                  selected: item.status == status,
                  onSelected: busy || item.status == status
                      ? null
                      : (_) => bloc.add(RoadmapStatusSet(
                          item: item, status: status, notify: _notifyOnDone)),
                ),
              ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              tooltip: loc.adminRoadmapMoveUp,
              icon: const Icon(Icons.arrow_upward, size: 18),
              onPressed: busy || index == 0
                  ? null
                  : () => bloc.add(RoadmapItemsReordered(
                      timeframe: tf, index: index, delta: -1)),
            ),
            IconButton(
              tooltip: loc.adminRoadmapMoveDown,
              icon: const Icon(Icons.arrow_downward, size: 18),
              onPressed: busy || index == tf.items.length - 1
                  ? null
                  : () => bloc.add(RoadmapItemsReordered(
                      timeframe: tf, index: index, delta: 1)),
            ),
            IconButton(
              tooltip: loc.commonEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: busy
                  ? null
                  : () => _openForm(context, loc, bloc, roadmap, editing: item),
            ),
            IconButton(
              tooltip: loc.commonDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: busy
                  ? null
                  : () async {
                      final confirmed = await confirmDialog(
                        context,
                        title: loc.adminRoadmapDeleteTitle,
                        message: item.text,
                        destructive: true,
                      );
                      if (confirmed && context.mounted) {
                        bloc.add(RoadmapItemDeleted(item: item));
                      }
                    },
            ),
          ],
        ),
        const Divider(height: 12),
      ],
    );
  }

  Future<void> _openForm(BuildContext context, AppLocalizations loc,
      RoadmapBloc bloc, Roadmap roadmap,
      {RoadmapItem? editing}) async {
    final textController = TextEditingController(text: editing?.text ?? '');
    final ownerController = TextEditingController(text: editing?.owner ?? '');
    final noteController = TextEditingController(text: editing?.note ?? '');
    var timeframeId = editing?.timeframeId ?? roadmap.timeframes.first.id;
    var status = editing?.status ?? RoadmapStatus.planned;
    var targetDate = editing?.targetDate ?? '';

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                editing == null
                    ? loc.adminRoadmapFormCreateTitle
                    : loc.adminRoadmapFormEditTitle,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: timeframeId,
                decoration: InputDecoration(
                  labelText: loc.adminRoadmapFormTimeframe,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final tf in roadmap.timeframes)
                    DropdownMenuItem<int>(value: tf.id, child: Text(tf.nameBn)),
                ],
                onChanged: (v) => timeframeId = v ?? timeframeId,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: textController,
                maxLength: roadmapTextMax,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: loc.adminRoadmapFormText,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (editing == null) ...[
                Wrap(
                  children: [
                    for (final statusOption in const [
                      RoadmapStatus.planned,
                      RoadmapStatus.inProgress,
                      RoadmapStatus.done,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_statusLabel(loc, statusOption)),
                          selected: status == statusOption,
                          onSelected: (_) => status = statusOption,
                        ),
                      ),
                  ],
                ),
              ],
              DateField(
                label: loc.adminRoadmapFormTargetDate,
                value: targetDate,
                onChanged: (v) => targetDate = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ownerController,
                maxLength: roadmapOwnerMax,
                decoration: InputDecoration(
                  labelText: loc.adminRoadmapFormOwner,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                maxLength: roadmapNoteMax,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: loc.adminRoadmapFormNote,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: loc.commonSave,
                  onPressed: () async {
                    final text = textController.text.trim();
                    if (text.isEmpty) {
                      showAppToast(
                          sheetContext, loc.adminRoadmapErrorsTextRequired,
                          error: true);
                      return;
                    }
                    final ok = editing == null
                        ? await dispatchForBool(
                            bloc,
                            (c) => RoadmapItemCreated(
                                completer: c,
                                timeframeId: timeframeId,
                                text: text,
                                status: status,
                                targetDate:
                                    targetDate.isEmpty ? null : targetDate,
                                owner: ownerController.text.trim(),
                                note: noteController.text.trim(),
                                notify: _notifyOnDone))
                        : await dispatchForBool(
                            bloc,
                            (c) => RoadmapItemUpdated(
                                completer: c,
                                item: editing,
                                text: text,
                                timeframeId: timeframeId,
                                targetDate: targetDate,
                                owner: ownerController.text.trim(),
                                note: noteController.text.trim()));
                    if (sheetContext.mounted && ok) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openArchiveDialog(
      BuildContext context, AppLocalizations loc, RoadmapBloc bloc) async {
    var onlyDone = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(loc.adminRoadmapArchiveTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.adminRoadmapArchiveMessage),
              CheckboxListTile(
                value: onlyDone,
                title: Text(loc.adminRoadmapArchiveOnlyDone),
                onChanged: (v) => setDialogState(() => onlyDone = v ?? true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.adminRoadmapArchiveConfirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      bloc.add(RoadmapArchived(onlyDone: onlyDone));
    }
  }

  void _openHistorySheet(
      BuildContext context, AppLocalizations loc, RoadmapBloc bloc) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => BlocProvider.value(
        value: bloc,
        child: BlocBuilder<RoadmapBloc, RoadmapState>(
          builder: (sheetContext, state) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(loc.adminRoadmapArchiveHistory,
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              if (state.history == null)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.history!.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(loc.adminRoadmapArchiveEmpty),
                )
              else
                for (final cycle in state.history!)
                  AppCard(
                    title: cycle.archivedAt.substring(0, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.adminRoadmapArchiveCycleSummary(
                            cycle.total, cycle.done)),
                        for (final item in cycle.items)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.text),
                            trailing: item.status == RoadmapStatus.done
                                ? const Icon(Icons.check)
                                : null,
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
