import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/audit_repository.dart';
import '../data/rbac_repository.dart';
import '../domain/audit_entities.dart';
import '../presentation/bloc/audit_log_bloc.dart';

/// Port of the Angular AuditLogComponent: filter bar (date range, action,
/// actor, entity type — all client-side, matching the endpoint), paginated
/// timeline cards (a table on wide screens) and a detail bottom sheet with
/// the parsed JSON detail column.
class AuditLogPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;
  const AuditLogPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuditLogBloc(
        AuditRepository(sl<ApiClient>()),
        RbacRepository(sl<ApiClient>()),
      )..add(const AuditLogStarted()),
      child: const _AuditLogView(),
    );
  }
}

const Duration _refreshTimeout = Duration(seconds: 20);
final DateFormat _timeFmt = DateFormat('dd MMM yyyy, hh:mm a');

bool _isLoading(AuditLogState s) =>
    s.status == AuditLogStatus.initial || s.status == AuditLogStatus.loading;

class _AuditLogView extends StatelessWidget {
  const _AuditLogView();

  Future<void> _refresh(AuditLogBloc bloc) async {
    final done = bloc.stream
        .firstWhere((s) => !_isLoading(s))
        .timeout(_refreshTimeout);
    bloc.add(const AuditLogStarted());
    try {
      await done;
    } on TimeoutException {
      // Slow network: stop the spinner; the page shows the bloc's outcome.
    } on StateError {
      // Bloc closed (page left) before the reload finished.
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<AuditLogBloc>();
    return Scaffold(
      body: BlocBuilder<AuditLogBloc, AuditLogState>(
        buildWhen: (a, b) =>
            _isLoading(a) != _isLoading(b) || a.loadFailed != b.loadFailed,
        builder: (context, state) => PageBody(
          onRefresh: () => _refresh(bloc),
          children: [
            PageHeader(
              icon: Icons.manage_search_rounded,
              title: loc.adminAuditLogTitle,
              subtitle: loc.adminAuditLogSubtitle,
            ),
            if (_isLoading(state))
              const SkeletonLoader(lines: 8)
            else ...[
              if (state.loadFailed)
                InlineError(
                  message: loc.adminAuditLogErrorsLoadFailed,
                  onRetry: () => bloc.add(const AuditLogStarted()),
                ),
              const _FilterBar(),
              const _EntriesList(),
              const _PaginationFooter(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Badge variant for the action verb (mirrors the Angular actionClass colors).
StatusKind _actionKind(String verb) => switch (verb) {
      'approve' => StatusKind.approved,
      'reject' || 'delete' => StatusKind.rejected,
      'create' => StatusKind.pending,
      _ => StatusKind.neutral,
    };

IconData _actionIcon(String verb) => switch (verb) {
      'approve' => Icons.verified_outlined,
      'reject' => Icons.block,
      'delete' => Icons.delete_outline,
      'create' => Icons.add_circle_outline,
      'update' => Icons.edit_outlined,
      _ => Icons.bolt_outlined,
    };

Color _actionColor(BuildContext context, String verb) {
  final scheme = Theme.of(context).colorScheme;
  return switch (verb) {
    'approve' => scheme.primary,
    'reject' || 'delete' => scheme.error,
    'create' => scheme.secondary,
    _ => scheme.onSurfaceVariant,
  };
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<AuditLogBloc>();
    return BlocBuilder<AuditLogBloc, AuditLogState>(
      buildWhen: (a, b) => a.filters != b.filters || a.entries != b.entries,
      builder: (context, state) {
        final filters = state.filters;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ResponsiveGrid(
                minItemWidth: 200,
                maxColumns: 5,
                children: [
                  _DateField(
                    label: loc.adminAuditLogFiltersDateFrom,
                    value: filters.dateFrom,
                    onChanged: (d) => bloc.add(AuditLogFiltersChanged(dateFrom: d)),
                  ),
                  _DateField(
                    label: loc.adminAuditLogFiltersDateTo,
                    value: filters.dateTo,
                    onChanged: (d) => bloc.add(AuditLogFiltersChanged(dateTo: d)),
                  ),
                  _FilterDropdown(
                    label: loc.adminAuditLogFiltersAction,
                    value: filters.action,
                    options: [for (final a in state.distinctActions) (a, a)],
                    onChanged: (v) => bloc.add(AuditLogFiltersChanged(action: v)),
                  ),
                  _FilterDropdown(
                    label: loc.adminAuditLogFiltersActor,
                    value: filters.actor,
                    options: [
                      for (final a in state.distinctActors) (a, state.actorLabel(a)),
                    ],
                    onChanged: (v) => bloc.add(AuditLogFiltersChanged(actor: v)),
                  ),
                  _FilterDropdown(
                    label: loc.adminAuditLogFiltersEntityType,
                    value: filters.entityType,
                    options: [for (final t in state.distinctEntityTypes) (t, t)],
                    onChanged: (v) => bloc.add(AuditLogFiltersChanged(entityType: v)),
                  ),
                ],
              ),
              if (filters.isActive)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: AppButton(
                      label: loc.superadminAuditClearFilters,
                      variant: AppButtonVariant.ghost,
                      icon: Icons.filter_alt_off_outlined,
                      onPressed: () => bloc.add(const AuditLogFiltersCleared()),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Dropdown with an "All" option (empty string) and ellipsized labels.
class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem(value: '', child: Text(loc.adminAuditLogFiltersAll)),
        for (final (v, text) in options)
          DropdownMenuItem(
            value: v,
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => onChanged(v ?? ''),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onChanged});

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    return InkWell(
      onTap: () => _pick(context),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value == null
              ? const Icon(Icons.event_outlined)
              : IconButton(
                  tooltip: material.clearButtonTooltip,
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          value == null ? '' : DateFormat('dd MMM yyyy').format(value!),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _EntriesList extends StatelessWidget {
  const _EntriesList();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocBuilder<AuditLogBloc, AuditLogState>(
      buildWhen: (a, b) =>
          a.pageEntries != b.pageEntries ||
          a.total != b.total ||
          a.actorLabels != b.actorLabels ||
          a.filters != b.filters,
      builder: (context, state) {
        if (state.total == 0) {
          return EmptyState(
            icon: Icons.history_toggle_off_rounded,
            message: state.filters.isActive
                ? loc.adminAuditLogNoEntriesMatch
                : loc.adminAuditLogNoEntries,
          );
        }
        if (context.isExpanded) return _AuditTable(state: state);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 6),
          child: ResponsiveGrid(
            minItemWidth: 340,
            maxColumns: 2,
            children: [
              for (final e in state.pageEntries) _EntryCard(entry: e, state: state),
            ],
          ),
        );
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.state});

  final AuditLogEntry entry;
  final AuditLogState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = _actionColor(context, entry.actionVerb);
    final hasDetail = entry.detail != null && entry.detail!.isNotEmpty;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasDetail ? () => _showDetailSheet(context, entry, state) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(_actionIcon(entry.actionVerb), size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(kind: _actionKind(entry.actionVerb), label: entry.action),
                        Text(_timeFmt.format(entry.created), style: theme.textTheme.bodySmall),
                      ],
                    ),
                    Text(
                      state.actorLabel(entry.actorAdminId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      '${entry.entityType} #${entry.entityId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (hasDetail)
                      Text(
                        entry.detail!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
              ),
              if (hasDetail)
                Icon(Icons.chevron_right, semanticLabel: loc.adminAuditLogDetailsView),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wide-screen table; scrolls horizontally if the window is still too narrow.
class _AuditTable extends StatelessWidget {
  const _AuditTable({required this.state});

  final AuditLogState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              showCheckboxColumn: false,
              headingTextStyle: theme.textTheme.labelLarge,
              columns: [
                DataColumn(label: Text(loc.adminAuditLogTableTime)),
                DataColumn(label: Text(loc.adminAuditLogTableAction)),
                DataColumn(label: Text(loc.adminAuditLogTableActor)),
                DataColumn(label: Text(loc.adminAuditLogTableEntity)),
                DataColumn(label: Text(loc.adminAuditLogTableDetail)),
              ],
              rows: [for (final e in state.pageEntries) _row(context, e)],
            ),
          ),
        ),
      ),
    );
  }

  DataRow _row(BuildContext context, AuditLogEntry e) {
    final loc = AppLocalizations.of(context);
    final hasDetail = e.detail != null && e.detail!.isNotEmpty;
    return DataRow(
      onSelectChanged: hasDetail ? (_) => _showDetailSheet(context, e, state) : null,
      cells: [
        DataCell(Text(_timeFmt.format(e.created))),
        DataCell(StatusBadge(kind: _actionKind(e.actionVerb), label: e.action)),
        DataCell(Text(state.actorLabel(e.actorAdminId))),
        DataCell(Text('${e.entityType} #${e.entityId}')),
        DataCell(
          hasDetail
              ? TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(loc.adminAuditLogDetailsView),
                  onPressed: () => _showDetailSheet(context, e, state),
                )
              : const Text('—'),
        ),
      ],
    );
  }
}

void _showDetailSheet(BuildContext context, AuditLogEntry entry, AuditLogState state) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _DetailSheet(entry: entry, state: state),
  );
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.entry, required this.state});

  final AuditLogEntry entry;
  final AuditLogState state;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pairs = parseAuditDetail(entry.detail);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(loc.adminAuditLogDetailsTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(kind: _actionKind(entry.actionVerb), label: entry.action),
              Text(_timeFmt.format(entry.created), style: theme.textTheme.bodySmall),
            ],
          ),
          DetailRow(
            icon: Icons.person_outline,
            label: loc.adminAuditLogTableActor,
            value: state.actorLabel(entry.actorAdminId),
          ),
          DetailRow(
            icon: Icons.dataset_outlined,
            label: loc.adminAuditLogTableEntity,
            value: '${entry.entityType} #${entry.entityId}',
          ),
          const Divider(height: 20),
          Flexible(
            child: pairs.isEmpty
                ? const Text('—')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final pair in pairs)
                        DetailRow(label: pair.key, value: pair.value),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: loc.adminAuditLogDetailsClose,
            variant: AppButtonVariant.secondary,
            expanded: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<AuditLogBloc>();
    return BlocBuilder<AuditLogBloc, AuditLogState>(
      buildWhen: (a, b) =>
          a.page != b.page || a.pageSize != b.pageSize || a.total != b.total,
      builder: (context, state) {
        if (state.total == 0) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 12),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                loc.adminAuditLogPaginationRange(
                    state.rangeFrom, state.rangeTo, state.total),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(loc.adminAuditLogPaginationPageSize,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: state.pageSize,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final size in kAuditPageSizes)
                        DropdownMenuItem(value: size, child: Text('$size')),
                    ],
                    onChanged: (size) {
                      if (size != null) bloc.add(AuditLogPageSizeChanged(size));
                    },
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.outlined(
                    tooltip: loc.adminAuditLogPaginationPrev,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: state.page <= 1
                        ? null
                        : () => bloc.add(AuditLogPageChanged(state.page - 1)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('${state.page} / ${state.totalPages}'),
                  ),
                  IconButton.outlined(
                    tooltip: loc.adminAuditLogPaginationNext,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: state.page >= state.totalPages
                        ? null
                        : () => bloc.add(AuditLogPageChanged(state.page + 1)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
