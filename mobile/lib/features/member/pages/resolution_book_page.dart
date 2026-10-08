import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/resolution_book_repository.dart';
import '../domain/resolution_book_entities.dart';
import '../presentation/bloc/resolution_book_bloc.dart';
import '../presentation/widgets/member_ui.dart';

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
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              tooltip: loc.rbActionsAddMeeting,
              onPressed: () => context.go('/resolution-book/add'),
              icon: const Icon(Icons.add),
              label: Text(loc.rbActionsAddMeeting),
            )
          : null,
      body: BlocBuilder<ResolutionBookBloc, ResolutionBookState>(
        builder: (context, state) {
          final bloc = context.read<ResolutionBookBloc>();
          final hasData = state.summary != null || state.meetings.isNotEmpty;
          if (state.status == ResolutionBookStatus.loading && !hasData) {
            return const SkeletonLoader(lines: 8);
          }
          if (state.error && !hasData) {
            return InlineError(
              message: loc.rbLoadError,
              onRetry: () => bloc.add(const ResolutionBookLoaded()),
            );
          }
          return PageBody(
            // Leave room so the FAB never hides the pager.
            padding: EdgeInsets.only(bottom: canManage ? 96 : 24),
            onRefresh: () => reloadAndWait<ResolutionBookState>(
              bloc,
              () => bloc.add(const ResolutionBookLoaded()),
              (s) => s.status != ResolutionBookStatus.loading && !s.listLoading,
            ),
            children: [
              PageHeader(title: loc.rbTitle, subtitle: loc.rbSubtitle, icon: Icons.menu_book_outlined),
              if (state.error)
                NoticeBanner(
                  tone: NoticeTone.error,
                  message: loc.rbLoadError,
                  action: TextButton(
                    onPressed: () => bloc.add(const ResolutionBookLoaded()),
                    child: Text(loc.commonRetry),
                  ),
                ),
              if (state.summary != null) Gutter(vertical: 6, child: _SummaryGrid(summary: state.summary!)),
              _Filters(state: state, bloc: bloc, search: _search),
              SectionTitle(loc.rbListTitle),
              ..._list(context, state, loc, bloc),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _list(
    BuildContext context,
    ResolutionBookState state,
    AppLocalizations loc,
    ResolutionBookBloc bloc,
  ) {
    if (state.listLoading) return const [SkeletonLoader(lines: 3, height: 88)];
    if (state.meetings.isEmpty) {
      return [
        EmptyState(
          message: state.hasFilters ? loc.rbListEmptyFiltered : loc.rbListEmpty,
          icon: Icons.menu_book_outlined,
        ),
      ];
    }
    return [
      Gutter(
        child: ResponsiveGrid(
          minItemWidth: 340,
          maxColumns: 3,
          children: [for (final m in state.meetings) _MeetingCard(meeting: m)],
        ),
      ),
      if (state.totalPages > 1)
        PagerBar(
          label: '${state.page + 1} / ${state.totalPages}',
          previousTooltip: loc.rbNavPrevious,
          nextTooltip: loc.rbNavNext,
          onPrevious: state.page > 0 ? () => bloc.add(ResolutionBookPageChanged(state.page - 1)) : null,
          onNext: state.page < state.totalPages - 1
              ? () => bloc.add(ResolutionBookPageChanged(state.page + 1))
              : null,
        ),
    ];
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final MeetingSummary summary;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ResponsiveGrid(
      minItemWidth: 240,
      maxColumns: 4,
      children: [
        StatTile(
          label: loc.rbSummaryTotalMeetings,
          value: '${summary.totalMeetings}',
          icon: Icons.event_note_outlined,
        ),
        StatTile(
          label: loc.rbSummaryThisYear,
          value: '${summary.meetingsThisYear}',
          icon: Icons.calendar_today_outlined,
          accent: AppColors.gold,
        ),
        StatTile(
          label: loc.rbSummaryAvgAttendance,
          value: '${summary.averageAttendancePercent.toStringAsFixed(0)}%',
          icon: Icons.groups_outlined,
        ),
        StatTile(
          label: loc.rbSummaryOpenActions,
          value: '${summary.openActionItems}',
          icon: Icons.pending_actions_outlined,
          accent: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.bloc, required this.search});

  final ResolutionBookState state;
  final ResolutionBookBloc bloc;
  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: loc.rbFiltersSearchPlaceholder,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: loc.rbFiltersApply,
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => bloc.add(ResolutionBookFiltersChanged(query: search.text)),
              ),
            ),
            onSubmitted: (q) => bloc.add(ResolutionBookFiltersChanged(query: q)),
          ),
          const SizedBox(height: 12),
          FieldGrid(
            minFieldWidth: 220,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey('type-${state.meetingType}'),
                initialValue: state.meetingType,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: loc.rbFiltersType,
                  prefixIcon: const Icon(Icons.videocam_outlined),
                ),
                items: [
                  DropdownMenuItem(value: '', child: Text(loc.rbFiltersAllTypes)),
                  DropdownMenuItem(value: 'online', child: Text(loc.rbTypeOnline)),
                  DropdownMenuItem(value: 'offline', child: Text(loc.rbTypeOffline)),
                ],
                onChanged: (v) => bloc.add(ResolutionBookFiltersChanged(meetingType: v ?? '')),
              ),
              DropdownButtonFormField<String>(
                key: ValueKey('status-${state.meetingStatus}'),
                initialValue: state.meetingStatus,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: loc.rbFiltersStatus,
                  prefixIcon: const Icon(Icons.flag_outlined),
                ),
                items: [
                  DropdownMenuItem(value: '', child: Text(loc.rbFiltersAllStatuses)),
                  DropdownMenuItem(value: 'scheduled', child: Text(loc.rbStatusScheduled)),
                  DropdownMenuItem(value: 'completed', child: Text(loc.rbStatusCompleted)),
                  DropdownMenuItem(value: 'cancelled', child: Text(loc.rbStatusCancelled)),
                ],
                onChanged: (v) => bloc.add(ResolutionBookFiltersChanged(meetingStatus: v ?? '')),
              ),
            ],
          ),
          if (state.hasFilters)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  search.clear();
                  bloc.add(const ResolutionBookFiltersCleared());
                },
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: Text(loc.rbFiltersClear),
              ),
            ),
        ],
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.meeting});

  final MeetingListItem meeting;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final online = meeting.meetingType == MeetingType.online;
    final when = [meeting.date, if ((meeting.time ?? '').isNotEmpty) meeting.time!].join(' · ');
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: () => context.go('/resolution-book/meeting/${meeting.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LeadingIcon(icon: online ? Icons.videocam_outlined : Icons.groups_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meeting.meetingNo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(when, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _meetingBadge(meeting.status, loc),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              MetaChip(icon: Icons.wifi_tethering, text: online ? loc.rbTypeOnline : loc.rbTypeOffline),
              MetaChip(icon: Icons.gavel_outlined, text: loc.rbListResolutions(meeting.resolutionCount)),
              MetaChip(
                icon: Icons.how_to_reg_outlined,
                text: loc.rbListAttendance(meeting.attendancePresent, meeting.attendanceTotal),
              ),
              if (meeting.chairperson.isNotEmpty)
                MetaChip(icon: Icons.person_outline, text: meeting.chairperson),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meetingBadge(MeetingStatus status, AppLocalizations loc) {
    final (kind, label) = switch (status) {
      MeetingStatus.scheduled => (StatusKind.pending, loc.rbStatusScheduled),
      MeetingStatus.completed => (StatusKind.approved, loc.rbStatusCompleted),
      MeetingStatus.cancelled => (StatusKind.rejected, loc.rbStatusCancelled),
      MeetingStatus.unknown => (StatusKind.neutral, ''),
    };
    return StatusBadge(kind: kind, label: label);
  }
}
