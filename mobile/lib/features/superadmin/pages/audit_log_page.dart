import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/audit_repository.dart';
import '../data/rbac_repository.dart';
import '../domain/audit_entities.dart';
import '../presentation/bloc/audit_log_bloc.dart';

/// Port of the Angular AuditLogComponent: filter bar (date range, action,
/// actor, entity type — all client-side, matching the endpoint), paginated
/// list-cards and a detail bottom sheet with the parsed JSON detail column.
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

class _AuditLogView extends StatelessWidget {
  const _AuditLogView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(title: loc.adminAuditLogTitle, subtitle: loc.adminAuditLogSubtitle),
            Expanded(
              child: BlocBuilder<AuditLogBloc, AuditLogState>(
                builder: (context, state) {
                  if (state.status == AuditLogStatus.initial ||
                      state.status == AuditLogStatus.loading) {
                    return const SkeletonLoader(lines: 8);
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (state.loadFailed) ...[
                        InlineError(
                          message: loc.adminAuditLogErrorsLoadFailed,
                          onRetry: () =>
                              context.read<AuditLogBloc>().add(const AuditLogStarted()),
                        ),
                        const SizedBox(height: 8),
                      ],
                      const _FilterBar(),
                      const SizedBox(height: 12),
                      const _EntriesList(),
                      if (state.total > 0) ...[
                        const SizedBox(height: 8),
                        const _PaginationFooter(),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge variant for the action verb (mirrors the Angular actionClass colors).
StatusKind _actionKind(String verb) => switch (verb) {
      'approve' => StatusKind.approved,
      'reject' => StatusKind.rejected,
      'delete' => StatusKind.rejected,
      'create' => StatusKind.pending,
      'update' => StatusKind.neutral,
      _ => StatusKind.neutral,
    };

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<AuditLogBloc>();
    return BlocBuilder<AuditLogBloc, AuditLogState>(
      buildWhen: (a, b) => a.filters != b.filters,
      builder: (context, state) {
        final filters = state.filters;
        return AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: loc.adminAuditLogFiltersDateFrom,
                      value: filters.dateFrom,
                      onChanged: (d) => bloc.add(AuditLogFiltersChanged(dateFrom: d)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateField(
                      label: loc.adminAuditLogFiltersDateTo,
                      value: filters.dateTo,
                      onChanged: (d) => bloc.add(AuditLogFiltersChanged(dateTo: d)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: filters.action.isEmpty ? null : filters.action,
                decoration: InputDecoration(
                  labelText: loc.adminAuditLogFiltersAction,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: '', child: Text(loc.adminAuditLogFiltersAll)),
                  for (final a in state.distinctActions) DropdownMenuItem(value: a, child: Text(a)),
                ],
                onChanged: (value) => bloc.add(AuditLogFiltersChanged(action: value ?? '')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: filters.actor.isEmpty ? null : filters.actor,
                decoration: InputDecoration(
                  labelText: loc.adminAuditLogFiltersActor,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: '', child: Text(loc.adminAuditLogFiltersAll)),
                  for (final a in state.distinctActors)
                    DropdownMenuItem(value: a, child: Text(state.actorLabel(a))),
                ],
                onChanged: (value) => bloc.add(AuditLogFiltersChanged(actor: value ?? '')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: filters.entityType.isEmpty ? null : filters.entityType,
                decoration: InputDecoration(
                  labelText: loc.adminAuditLogFiltersEntityType,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: '', child: Text(loc.adminAuditLogFiltersAll)),
                  for (final t in state.distinctEntityTypes)
                    DropdownMenuItem(value: t, child: Text(t)),
                ],
                onChanged: (value) => bloc.add(AuditLogFiltersChanged(entityType: value ?? '')),
              ),
              if (filters.isActive) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: loc.superadminAuditClearFilters,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => bloc.add(const AuditLogFiltersCleared()),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onChanged});

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: value == null
            ? const Icon(Icons.calendar_today, size: 18)
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onChanged(null),
              ),
      ),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 10),
            lastDate: now,
          );
          if (picked != null) onChanged(picked);
        },
        child: Text(
          value == null ? '' : fmt.format(value!),
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
            message: state.filters.isActive
                ? loc.adminAuditLogNoEntriesMatch
                : loc.adminAuditLogNoEntries,
          );
        }
        final timeFmt = DateFormat('dd MMM yyyy, hh:mm a');
        return Column(
          children: [
            for (final e in state.pageEntries)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            timeFmt.format(e.created),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        StatusBadge(kind: _actionKind(e.actionVerb), label: e.action),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.actorLabel(e.actorAdminId),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${e.entityType} #${e.entityId}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (e.detail != null && e.detail!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _showDetailSheet(context, e, state),
                        child: Text(
                          _truncate(e.detail!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

String _truncate(String text, [int max = 40]) =>
    text.length > max ? '${text.substring(0, max)}…' : text;

void _showDetailSheet(BuildContext context, AuditLogEntry entry, AuditLogState state) {
  final loc = AppLocalizations.of(context);
  final timeFmt = DateFormat('dd MMM yyyy, hh:mm a');
  final pairs = parseAuditDetail(entry.detail);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.adminAuditLogDetailsTitle,
                style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${timeFmt.format(entry.created)} · '
              '${state.actorLabel(entry.actorAdminId)} · '
              '${entry.entityType} #${entry.entityId}',
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (pairs.isEmpty)
              const Text('—')
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final pair in pairs)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pair.key,
                                style: Theme.of(sheetContext).textTheme.labelSmall),
                            Text(pair.value,
                                style: Theme.of(sheetContext).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            AppButton(
              label: loc.adminAuditLogDetailsClose,
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
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
        return Column(
          children: [
            Text(
              loc.adminAuditLogPaginationRange(
                state.rangeFrom,
                state.rangeTo,
                state.total,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(loc.adminAuditLogPaginationPageSize,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: state.pageSize,
                  items: [
                    for (final size in kAuditPageSizes)
                      DropdownMenuItem(value: size, child: Text('$size')),
                  ],
                  onChanged: (size) {
                    if (size != null) bloc.add(AuditLogPageSizeChanged(size));
                  },
                ),
                const SizedBox(width: 16),
                AppButton(
                  label: loc.adminAuditLogPaginationPrev,
                  variant: AppButtonVariant.ghost,
                  onPressed: state.page <= 1
                      ? null
                      : () => bloc.add(AuditLogPageChanged(state.page - 1)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('${state.page} / ${state.totalPages}'),
                ),
                AppButton(
                  label: loc.adminAuditLogPaginationNext,
                  variant: AppButtonVariant.ghost,
                  onPressed: state.page >= state.totalPages
                      ? null
                      : () => bloc.add(AuditLogPageChanged(state.page + 1)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
