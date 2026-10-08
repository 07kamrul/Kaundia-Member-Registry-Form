import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../core/enums/enums.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/submissions_cubit.dart';
import '../presentation/widgets/management_widgets.dart';

/// Review queue: submissions filtered by status (Angular submissions-list).
class SubmissionsListPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const SubmissionsListPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => SubmissionsCubit(repository: AdminRepository(apiClient: sl<ApiClient>()))..load(),
      child: BlocBuilder<SubmissionsCubit, SubmissionsState>(builder: (context, state) {
        final cubit = context.read<SubmissionsCubit>();
        return ListView(
          children: [
            PageHeader(title: loc.adminSubmissionsListTitle, subtitle: loc.adminSubmissionsListSubtitle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<SubmissionStatus?>(
                initialValue: state.filter,
                decoration: InputDecoration(
                  labelText: loc.adminSubmissionsListFilterLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem<SubmissionStatus?>(
                    value: null,
                    child: Text(loc.adminSubmissionsListAllOption),
                  ),
                  for (final s in const [
                    SubmissionStatus.pending,
                    SubmissionStatus.approved,
                    SubmissionStatus.rejected,
                  ])
                    DropdownMenuItem<SubmissionStatus?>(
                      value: s,
                      child: Text(statusLabel(loc, s)),
                    ),
                ],
                onChanged: cubit.setFilter,
              ),
            ),
            if (state.loading)
              const SkeletonLoader(lines: 5)
            else if (state.error != null)
              InlineError(
                message: loc.adminSubmissionsListErrorsLoadFailed,
                onRetry: cubit.load,
              )
            else ...[
              if (state.items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: StatusBadge(
                    kind: switch (state.filter) {
                      SubmissionStatus.pending => StatusKind.pending,
                      SubmissionStatus.approved => StatusKind.approved,
                      SubmissionStatus.rejected => StatusKind.rejected,
                      _ => StatusKind.neutral,
                    },
                    label: '${state.items.length}',
                  ),
                ),
              AppDataTableCards<SubmissionSummary>(
                items: state.items,
                rowBuilder: (context, s) => _row(context, loc, s),
                onRowTap: (s) => context.go('/submissions/${s.id}'),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _row(BuildContext context, AppLocalizations loc, SubmissionSummary s) {
    final year = DateTime.tryParse(s.createdAt)?.year ?? DateTime.now().year;
    final reference = 'REF-$year-${s.id.padLeft(4, '0')}';
    final date = DateTime.tryParse(s.createdAt);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.fullName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                StatusBadge(
                  kind: switch (s.status) {
                    SubmissionStatus.pending => StatusKind.pending,
                    SubmissionStatus.approved => StatusKind.approved,
                    SubmissionStatus.rejected => StatusKind.rejected,
                    _ => StatusKind.neutral,
                  },
                  label: statusLabel(loc, s.status),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InfoRow(label: loc.adminSubmissionsListTableHeadersReference, value: reference),
            InfoRow(label: loc.adminSubmissionsListTableHeadersMobile, value: s.mobile),
            InfoRow(
              label: loc.adminSubmissionsListTableHeadersDate,
              value: date == null ? s.createdAt : DateFormat('yyyy-MM-dd').format(date),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: loc.adminSubmissionsListDetailsLink,
                icon: Icons.chevron_right,
                onPressed: () => context.go('/submissions/${s.id}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String statusLabel(AppLocalizations loc, SubmissionStatus status) => switch (status) {
      SubmissionStatus.pending => loc.adminStatusLabelsPending,
      SubmissionStatus.approved => loc.adminStatusLabelsApproved,
      SubmissionStatus.rejected => loc.adminStatusLabelsRejected,
      _ => loc.adminStatusLabelsAll,
    };
