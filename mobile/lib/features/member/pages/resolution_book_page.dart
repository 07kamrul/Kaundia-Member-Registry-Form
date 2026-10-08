import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/resolution_book_repository.dart';
import '../domain/resolution_book_entities.dart';
import '../presentation/bloc/resolution_book_bloc.dart';

/// Port of Angular ResolutionBookComponent: dashboard summary, filters,
/// paginated meeting list. The add/edit entry only appears with
/// manage_resolution_book.
class ResolutionBookPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const ResolutionBookPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ResolutionBookBloc(
        repository: ResolutionBookRepository(apiClient: sl<ApiClient>()),
      )..add(const ResolutionBookLoaded()),
      child: const _ResolutionBookView(),
    );
  }
}

class _ResolutionBookView extends StatefulWidget {
  const _ResolutionBookView();

  @override
  State<_ResolutionBookView> createState() => _ResolutionBookViewState();
}

class _ResolutionBookViewState extends State<_ResolutionBookView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final canManage = sl<SessionManager>().session?.can(AppPermissions.resolutionBookManage) ?? false;
    return Scaffold(
      body: BlocBuilder<ResolutionBookBloc, ResolutionBookState>(
        builder: (context, state) {
          final bloc = context.read<ResolutionBookBloc>();
          if (state.status == ResolutionBookStatus.loading) {
            return const SkeletonLoader(lines: 8);
          }
          if (state.error && state.meetings.isEmpty && state.summary == null) {
            return InlineError(
              message: loc.rbLoadError,
              onRetry: () => bloc.add(const ResolutionBookLoaded()),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              PageHeader(
                title: loc.rbTitle,
                subtitle: loc.rbSubtitle,
                actions: [
                  if (canManage)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IconButton(
                        tooltip: loc.rbActionsAddMeeting,
                        icon: const Icon(Icons.add),
                        onPressed: () => context.go('/resolution-book/add'),
                      ),
                    ),
                ],
              ),
              if (state.summary != null)
                AppCard(
                  child: Row(
                    children: [
                      _stat(context, loc.rbSummaryTotalMeetings,
                          '${state.summary!.totalMeetings}'),
                      _stat(context, loc.rbSummaryThisYear,
                          '${state.summary!.meetingsThisYear}'),
                      _stat(context, loc.rbSummaryAvgAttendance,
                          '${state.summary!.averageAttendancePercent.toStringAsFixed(0)}%'),
                      _stat(context, loc.rbSummaryOpenActions,
                          '${state.summary!.openActionItems}'),
                    ],
                  ),
                ),
              // Filters.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: loc.rbFiltersSearchPlaceholder,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (q) => bloc.add(ResolutionBookFiltersChanged(query: q)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    DropdownButton<String>(
                      value: state.meetingType,
                      hint: Text(loc.rbFiltersType),
                      items: [
                        DropdownMenuItem(value: '', child: Text(loc.rbFiltersAllTypes)),
                        DropdownMenuItem(value: 'online', child: Text(loc.rbTypeOnline)),
                        DropdownMenuItem(value: 'offline', child: Text(loc.rbTypeOffline)),
                      ],
                      onChanged: (v) => bloc.add(ResolutionBookFiltersChanged(meetingType: v ?? '')),
                    ),
                    DropdownButton<String>(
                      value: state.meetingStatus,
                      hint: Text(loc.rbFiltersStatus),
                      items: [
                        DropdownMenuItem(value: '', child: Text(loc.rbFiltersAllStatuses)),
                        DropdownMenuItem(value: 'scheduled', child: Text(loc.rbStatusScheduled)),
                        DropdownMenuItem(value: 'completed', child: Text(loc.rbStatusCompleted)),
                        DropdownMenuItem(value: 'cancelled', child: Text(loc.rbStatusCancelled)),
                      ],
                      onChanged: (v) => bloc.add(ResolutionBookFiltersChanged(meetingStatus: v ?? '')),
                    ),
                    if (state.hasFilters)
                      TextButton(
                        onPressed: () {
                          _search.clear();
                          bloc.add(const ResolutionBookFiltersCleared());
                        },
                        child: Text(loc.rbFiltersClear),
                      ),
                  ],
                ),
              ),
              if (state.listLoading)
                const SkeletonLoader(lines: 3)
              else if (state.meetings.isEmpty)
                EmptyState(
                  message: state.hasFilters ? loc.rbListEmptyFiltered : loc.rbListEmpty,
                  icon: Icons.menu_book_outlined,
                )
              else
                for (final meeting in state.meetings)
                  AppCard(
                    onTap: () => context.go('/resolution-book/meeting/${meeting.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                meeting.meetingNo,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            _meetingBadge(context, meeting.status, loc),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_typeLabel(meeting.meetingType, loc)} · ${loc.rbListResolutions}: ${meeting.resolutionCount}'
                          ' · ${loc.rbListAttendance}: ${meeting.attendancePresent}/${meeting.attendanceTotal}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              if (state.totalPages > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: state.page > 0
                          ? () => bloc.add(ResolutionBookPageChanged(state.page - 1))
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('${state.page + 1} / ${state.totalPages}'),
                    IconButton(
                      onPressed: state.page < state.totalPages - 1
                          ? () => bloc.add(ResolutionBookPageChanged(state.page + 1))
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _typeLabel(MeetingType type, AppLocalizations loc) =>
      type == MeetingType.online ? loc.rbTypeOnline : loc.rbTypeOffline;

  Widget _meetingBadge(BuildContext context, MeetingStatus status, AppLocalizations loc) {
    final (kind, label) = switch (status) {
      MeetingStatus.scheduled => (StatusKind.pending, loc.rbStatusScheduled),
      MeetingStatus.completed => (StatusKind.approved, loc.rbStatusCompleted),
      MeetingStatus.cancelled => (StatusKind.rejected, loc.rbStatusCancelled),
      MeetingStatus.unknown => (StatusKind.neutral, ''),
    };
    return StatusBadge(kind: kind, label: label);
  }
}
