import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/auth/session.dart';
import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/resolution_book_repository.dart';
import '../domain/resolution_book_entities.dart';
import '../presentation/bloc/resolution_book_detail_bloc.dart';

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
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView();

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final canManage =
        sl<SessionManager>().session?.can(AppPermissions.resolutionBookManage) ?? false;
    return Scaffold(
      body: BlocConsumer<ResolutionBookDetailBloc, ResolutionBookDetailState>(
        listener: (context, state) {
          final path = state.pdfSavedPath;
          if (path != null) {
            OpenFilex.open(path);
            context.read<ResolutionBookDetailBloc>().add(const ResolutionBookDetailPdfSavedPathCleared());
          }
        },
        builder: (context, state) {
          final bloc = context.read<ResolutionBookDetailBloc>();
          if (state.status == ResolutionBookStatus.loading) {
            return const SkeletonLoader(lines: 8);
          }
          if (state.error || state.meeting == null) {
            return InlineError(message: loc.rbLoadError, onRetry: () => bloc.add(ResolutionBookDetailLoadRequested(id ?? '')));
          }
          final meeting = state.meeting!;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              PageHeader(
                title: meeting.meetingNo,
                subtitle: meeting.date,
                actions: [
                  if (canManage)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: IconButton(
                        tooltip: loc.rbActionsEdit,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => context.go('/resolution-book/edit/${meeting.id}'),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
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
                      label: meeting.meetingType == MeetingType.online
                          ? loc.rbTypeOnline
                          : loc.rbTypeOffline,
                    ),
                    OutlinedButton.icon(
                      onPressed: state.pdfDownloading ? null : () => bloc.add(const ResolutionBookDetailPdfDownloadRequested()),
                      icon: state.pdfDownloading
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(loc.rbActionsPdf),
                    ),
                  ],
                ),
              ),
              if (state.exportError)
                InlineError(message: loc.rbExportError, onRetry: () => bloc.add(const ResolutionBookDetailPdfDownloadRequested())),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row(loc.rbDetailChair, meeting.chairperson),
                    if (meeting.nextMeetingDate != null)
                      _row(loc.rbDetailNextMeeting, meeting.nextMeetingDate!),
                    if (meeting.createdBy != null)
                      _row(loc.rbDetailCreatedBy(meeting.createdBy!), ''),
                    if (meeting.updatedAt != null)
                      _row(loc.rbDetailLastUpdated(meeting.updatedAt!), ''),
                  ],
                ),
              ),
              AppTabs(
                labels: [
                  loc.rbTabsOverview,
                  loc.rbTabsAttendance,
                  loc.rbTabsResolutions,
                  loc.rbTabsRecordings,
                ],
                selectedIndex: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              if (_tab == 0)
                AppCard(
                  title: loc.rbDetailAgenda,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meeting.agenda),
                      if (meeting.summary != null) ...[
                        const SizedBox(height: 8),
                        Text(loc.rbDetailSummary,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(meeting.summary!),
                      ],
                    ],
                  ),
                ),
              if (_tab == 1)
                AppCard(
                  title: loc.rbDetailAttendanceTitle,
                  child: meeting.attendance.isEmpty
                      ? Text(loc.rbDetailNoAttendance)
                      : Column(
                          children: [
                            for (final entry in meeting.attendance)
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  entry.status == AttendanceStatus.present
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: entry.status == AttendanceStatus.present
                                      ? Colors.green.shade700
                                      : Theme.of(context).colorScheme.error,
                                ),
                                title: Text(entry.member.fullName),
                                trailing: Text(entry.status == AttendanceStatus.present
                                    ? loc.rbAttendancePresent
                                    : loc.rbAttendanceAbsent),
                              ),
                          ],
                        ),
                ),
              if (_tab == 2)
                AppCard(
                  title: loc.rbTabsResolutions,
                  child: meeting.resolutions.isEmpty
                      ? Text(loc.rbDetailNoResolutions)
                      : Column(
                          children: [
                            for (final r in meeting.resolutions)
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text('${loc.rbDetailResolutionNo} ${r.resolutionNo}: ${r.decision}'),
                                subtitle: Text(
                                  '${loc.rbVoteFor} ${r.voteFor} · ${loc.rbVoteAgainst} ${r.voteAgainst} · ${loc.rbVoteNeutral} ${r.voteNeutral}'
                                  '${r.task != null ? '\n${r.task}' : ''}',
                                ),
                                trailing: canManage
                                    ? _statusDropdown(context, bloc, state, r)
                                    : StatusBadge(
                                        kind: switch (r.status) {
                                          ResolutionStatus.done => StatusKind.approved,
                                          ResolutionStatus.inProgress => StatusKind.pending,
                                          _ => StatusKind.neutral,
                                        },
                                        label: _resolutionLabel(r.status, loc),
                                      ),
                              ),
                          ],
                        ),
                ),
              if (_tab == 3)
                AppCard(
                  title: loc.rbRecordingsTitle,
                  child: meeting.recordings.isEmpty
                      ? Text(loc.rbRecordingsEmpty)
                      : Column(
                          children: [
                            for (final rec in meeting.recordings)
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.videocam_outlined),
                                title: Text(rec.originalName),
                                subtitle: Text('${rec.fileSize} bytes'),
                              ),
                          ],
                        ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusDropdown(
    BuildContext context,
    ResolutionBookDetailBloc bloc,
    ResolutionBookDetailState state,
    Resolution r,
  ) {
    final loc = AppLocalizations.of(context);
    final saving = state.statusSavingId == r.id;
    return DropdownButton<ResolutionStatus>(
      value: r.status,
      items: [
        DropdownMenuItem(value: ResolutionStatus.pending, child: Text(loc.rbResolutionPending)),
        DropdownMenuItem(value: ResolutionStatus.inProgress, child: Text(loc.rbResolutionInProgress)),
        DropdownMenuItem(value: ResolutionStatus.done, child: Text(loc.rbResolutionDone)),
      ],
      onChanged: saving
          ? null
          : (next) {
              if (next != null) bloc.add(ResolutionBookDetailResolutionStatusChanged(r.id, next));
            },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
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

String _resolutionLabel(ResolutionStatus status, AppLocalizations loc) => switch (status) {
      ResolutionStatus.pending => loc.rbResolutionPending,
      ResolutionStatus.inProgress => loc.rbResolutionInProgress,
      ResolutionStatus.done => loc.rbResolutionDone,
      ResolutionStatus.unknown => '',
    };
