import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/auth/session.dart';
import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/resolution_book_repository.dart';
import '../domain/resolution_book_entities.dart';
import '../presentation/bloc/resolution_book_detail_bloc.dart';
import '../presentation/widgets/meeting_detail_sections.dart';
import '../presentation/widgets/member_ui.dart';

/// Port of Angular MeetingDetailComponent: overview / attendance / resolutions
/// / recordings tabs, minutes PDF export, and (with manage_resolution_book)
/// resolution status updates.
class ResolutionBookDetailPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const ResolutionBookDetailPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ResolutionBookDetailBloc(
        repository: ResolutionBookRepository(apiClient: sl<ApiClient>()),
      )..add(ResolutionBookDetailLoadRequested(id ?? '')),
      child: _DetailView(id: id ?? ''),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView({required this.id});

  final String id;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  static const _tabCount = 4;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final canManage =
        sl<SessionManager>().session?.can(AppPermissions.resolutionBookManage) ?? false;
    return Scaffold(
      body: BlocListener<ResolutionBookDetailBloc, ResolutionBookDetailState>(
        listenWhen: (prev, next) => !prev.statusSaveFailed && next.statusSaveFailed,
        listener: (context, _) => showAppToast(context, loc.commonServerError, error: true),
        child: _body(context, loc, canManage),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations loc, bool canManage) {
    return BlocConsumer<ResolutionBookDetailBloc, ResolutionBookDetailState>(
      listener: (context, state) {
        final path = state.pdfSavedPath;
        if (path != null) {
          OpenFilex.open(path);
          context.read<ResolutionBookDetailBloc>().add(const ResolutionBookDetailPdfSavedPathCleared());
        }
      },
      builder: (context, state) {
        final bloc = context.read<ResolutionBookDetailBloc>();
        final meeting = state.meeting;
        if (state.status == ResolutionBookStatus.loading && meeting == null) {
          return const SkeletonLoader(lines: 8);
        }
        if (meeting == null || (state.error && state.status == ResolutionBookStatus.failure)) {
          return InlineError(
            message: loc.rbLoadError,
            onRetry: () => bloc.add(ResolutionBookDetailLoadRequested(widget.id)),
          );
        }
        return PageBody(
          maxWidth: Breakpoints.formMaxWidth,
          onRefresh: () => reloadAndWait<ResolutionBookDetailState>(
            bloc,
            () => bloc.add(ResolutionBookDetailLoadRequested(widget.id)),
            (s) => s.status != ResolutionBookStatus.loading,
          ),
          children: _content(context, loc, meeting, state, bloc, canManage),
        );
      },
    );
  }

  List<Widget> _content(
    BuildContext context,
    AppLocalizations loc,
    MeetingDetail meeting,
    ResolutionBookDetailState state,
    ResolutionBookDetailBloc bloc,
    bool canManage,
  ) {
    return [
      PageHeader(
        title: meeting.meetingNo,
        subtitle: [meeting.date, if ((meeting.time ?? '').isNotEmpty) meeting.time!].join(' · '),
        icon: Icons.event_note_outlined,
        actions: [
          if (canManage)
            IconButton.filledTonal(
              tooltip: loc.rbActionsEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.go('/resolution-book/edit/${meeting.id}'),
            ),
        ],
      ),
      _StatusBar(meeting: meeting, state: state, bloc: bloc),
      if (state.exportError)
        NoticeBanner(
          tone: NoticeTone.error,
          message: loc.rbExportError,
          action: TextButton(
            onPressed: () => bloc.add(const ResolutionBookDetailPdfDownloadRequested()),
            child: Text(loc.commonRetry),
          ),
        ),
      _InfoCard(meeting: meeting),
      Gutter(
        vertical: 4,
        child: DefaultTabController(
          length: _tabCount,
          initialIndex: _tab,
          child: AppTabs(
            labels: [
              loc.rbTabsOverview,
              loc.rbTabsAttendance,
              loc.rbTabsResolutions,
              loc.rbTabsRecordings,
            ],
            selectedIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ),
      ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_tab),
          child: _tabBody(meeting, state, bloc, canManage),
        ),
      ),
    ];
  }

  Widget _tabBody(
    MeetingDetail meeting,
    ResolutionBookDetailState state,
    ResolutionBookDetailBloc bloc,
    bool canManage,
  ) {
    return switch (_tab) {
      0 => MeetingOverviewCard(meeting: meeting),
      1 => MeetingAttendanceCard(meeting: meeting),
      2 => MeetingResolutionsCard(
          meeting: meeting,
          canManage: canManage,
          savingId: state.statusSavingId,
          onStatusChanged: (r, next) =>
              bloc.add(ResolutionBookDetailResolutionStatusChanged(r.id, next)),
        ),
      _ => MeetingRecordingsCard(meeting: meeting),
    };
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.meeting, required this.state, required this.bloc});

  final MeetingDetail meeting;
  final ResolutionBookDetailState state;
  final ResolutionBookDetailBloc bloc;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Gutter(
      vertical: 4,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StatusBadge(
            kind: switch (meeting.status) {
              MeetingStatus.scheduled => StatusKind.pending,
              MeetingStatus.completed => StatusKind.approved,
              MeetingStatus.cancelled => StatusKind.rejected,
              MeetingStatus.unknown => StatusKind.neutral,
            },
            label: _statusLabel(meeting.status, loc),
          ),
          StatusBadge(
            kind: StatusKind.neutral,
            label: meeting.meetingType == MeetingType.online ? loc.rbTypeOnline : loc.rbTypeOffline,
          ),
          AppButton(
            label: loc.rbActionsPdf,
            variant: AppButtonVariant.secondary,
            icon: Icons.picture_as_pdf_outlined,
            loading: state.pdfDownloading,
            onPressed: () => bloc.add(const ResolutionBookDetailPdfDownloadRequested()),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.meeting});

  final MeetingDetail meeting;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailRow(label: loc.rbDetailChair, value: meeting.chairperson, icon: Icons.person_outline),
          DetailRow(
            label: loc.rbTabsAttendance,
            value: loc.rbListAttendance(meeting.attendancePresent, meeting.attendanceTotal),
            icon: Icons.how_to_reg_outlined,
          ),
          DetailRow(
            label: loc.rbDetailNextMeeting,
            value: meeting.nextMeetingDate ?? loc.rbDetailNotSet,
            icon: Icons.event_repeat_outlined,
          ),
          if (meeting.createdBy != null || meeting.updatedAt != null) ...[
            const Divider(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                if (meeting.createdBy != null)
                  MetaChip(icon: Icons.edit_note, text: loc.rbDetailCreatedBy(meeting.createdBy!)),
                if (meeting.updatedAt != null)
                  MetaChip(icon: Icons.update, text: loc.rbDetailLastUpdated(meeting.updatedAt!)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _statusLabel(MeetingStatus status, AppLocalizations loc) => switch (status) {
      MeetingStatus.scheduled => loc.rbStatusScheduled,
      MeetingStatus.completed => loc.rbStatusCompleted,
      MeetingStatus.cancelled => loc.rbStatusCancelled,
      MeetingStatus.unknown => '',
    };
