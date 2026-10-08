import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/resolution_book_entities.dart';
import 'member_ui.dart';

/// Tab bodies for the meeting detail page (overview / attendance /
/// resolutions / recordings). Presentation only — callbacks carry actions.

class MeetingOverviewCard extends StatelessWidget {
  const MeetingOverviewCard({super.key, required this.meeting});

  final MeetingDetail meeting;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = meeting.summary;
    return AppCard(
      title: loc.rbDetailAgenda,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(meeting.agenda, style: theme.textTheme.bodyMedium),
          const Divider(height: 28),
          Text(loc.rbDetailSummary, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          if (summary == null || summary.isEmpty)
            Text(
              loc.rbDetailNoSummary,
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            )
          else
            SelectableText(summary, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class MeetingAttendanceCard extends StatelessWidget {
  const MeetingAttendanceCard({super.key, required this.meeting});

  final MeetingDetail meeting;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppCard(
      title: loc.rbDetailAttendanceTitle,
      trailing: Text(
        loc.rbListAttendance(meeting.attendancePresent, meeting.attendanceTotal),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      child: meeting.attendance.isEmpty
          ? _MutedText(loc.rbDetailNoAttendance)
          : Column(
              children: [
                for (final entry in meeting.attendance) _AttendanceRow(entry: entry),
              ],
            ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.entry});

  final AttendanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final present = entry.status == AttendanceStatus.present;
    final name = entry.member.fullName.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              name.isEmpty ? '—' : name.substring(0, 1),
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                if ((entry.member.memberId ?? '').isNotEmpty)
                  Text(entry.member.memberId!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(
            kind: present ? StatusKind.approved : StatusKind.rejected,
            label: present ? loc.rbAttendancePresent : loc.rbAttendanceAbsent,
          ),
        ],
      ),
    );
  }
}

class MeetingResolutionsCard extends StatelessWidget {
  const MeetingResolutionsCard({
    super.key,
    required this.meeting,
    required this.canManage,
    required this.savingId,
    required this.onStatusChanged,
  });

  final MeetingDetail meeting;
  final bool canManage;
  final String? savingId;
  final void Function(Resolution resolution, ResolutionStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppCard(
      title: loc.rbTabsResolutions,
      child: meeting.resolutions.isEmpty
          ? _MutedText(loc.rbDetailNoResolutions)
          : Column(
              children: [
                for (var i = 0; i < meeting.resolutions.length; i++) ...[
                  if (i > 0) const Divider(height: 24),
                  _ResolutionTile(
                    resolution: meeting.resolutions[i],
                    canManage: canManage,
                    saving: savingId == meeting.resolutions[i].id,
                    onStatusChanged: onStatusChanged,
                  ),
                ],
              ],
            ),
    );
  }
}

class _ResolutionTile extends StatelessWidget {
  const _ResolutionTile({
    required this.resolution,
    required this.canManage,
    required this.saving,
    required this.onStatusChanged,
  });

  final Resolution resolution;
  final bool canManage;
  final bool saving;
  final void Function(Resolution resolution, ResolutionStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final r = resolution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text(
              loc.rbDetailResolutionNo(r.resolutionNo),
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
            ),
            canManage ? _statusMenu(loc) : _statusBadge(loc),
          ],
        ),
        const SizedBox(height: 6),
        Text(r.decision, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _VoteChip(label: loc.rbVoteFor, count: r.voteFor, color: AppColors.emerald600),
            _VoteChip(label: loc.rbVoteAgainst, count: r.voteAgainst, color: theme.colorScheme.error),
            _VoteChip(label: loc.rbVoteNeutral, count: r.voteNeutral, color: AppColors.gold),
          ],
        ),
        if ((r.task ?? '').isNotEmpty || r.assignedTo != null || (r.dueDate ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                if ((r.task ?? '').isNotEmpty) MetaChip(icon: Icons.task_alt, text: r.task!),
                if (r.assignedTo != null)
                  MetaChip(icon: Icons.person_outline, text: r.assignedTo!.fullName),
                if ((r.dueDate ?? '').isNotEmpty) MetaChip(icon: Icons.event_outlined, text: r.dueDate!),
              ],
            ),
          ),
      ],
    );
  }

  Widget _statusBadge(AppLocalizations loc) {
    return StatusBadge(
      kind: switch (resolution.status) {
        ResolutionStatus.done => StatusKind.approved,
        ResolutionStatus.inProgress => StatusKind.pending,
        _ => StatusKind.neutral,
      },
      label: resolutionStatusLabel(resolution.status, loc),
    );
  }

  Widget _statusMenu(AppLocalizations loc) {
    final current = resolution.status == ResolutionStatus.unknown ? null : resolution.status;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (saving)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        DropdownButton<ResolutionStatus>(
          value: current,
          // Short hint: DropdownButton sizes to its widest child, and the
          // long Bangla "resolution status" label overflows on phones.
          hint: const Text('—'),
          isDense: true,
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem(value: ResolutionStatus.pending, child: Text(loc.rbResolutionPending)),
            DropdownMenuItem(value: ResolutionStatus.inProgress, child: Text(loc.rbResolutionInProgress)),
            DropdownMenuItem(value: ResolutionStatus.done, child: Text(loc.rbResolutionDone)),
          ],
          onChanged: saving
              ? null
              : (next) {
                  if (next != null) onStatusChanged(resolution, next);
                },
        ),
      ],
    );
  }
}

class _VoteChip extends StatelessWidget {
  const _VoteChip({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class MeetingRecordingsCard extends StatelessWidget {
  const MeetingRecordingsCard({super.key, required this.meeting});

  final MeetingDetail meeting;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppCard(
      title: loc.rbRecordingsTitle,
      child: meeting.recordings.isEmpty
          ? _MutedText(loc.rbRecordingsEmpty)
          : Column(
              children: [
                for (final rec in meeting.recordings)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        LeadingIcon(icon: _recordingIcon(rec.fileType)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rec.originalName, maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(
                                [
                                  _formatBytes(rec.fileSize),
                                  if ((rec.uploadedAt ?? '').isNotEmpty) rec.uploadedAt!,
                                ].join(' · '),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  IconData _recordingIcon(RecordingType type) => switch (type) {
        RecordingType.video => Icons.videocam_outlined,
        RecordingType.audio => Icons.graphic_eq,
        RecordingType.screenshot => Icons.image_outlined,
        RecordingType.chatLog => Icons.chat_outlined,
        RecordingType.unknown => Icons.insert_drive_file_outlined,
      };

  String _formatBytes(int bytes) {
    const kb = 1024;
    if (bytes < kb) return '$bytes B';
    if (bytes < kb * kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    if (bytes < kb * kb * kb) return '${(bytes / (kb * kb)).toStringAsFixed(1)} MB';
    return '${(bytes / (kb * kb * kb)).toStringAsFixed(2)} GB';
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

String resolutionStatusLabel(ResolutionStatus status, AppLocalizations loc) => switch (status) {
      ResolutionStatus.pending => loc.rbResolutionPending,
      ResolutionStatus.inProgress => loc.rbResolutionInProgress,
      ResolutionStatus.done => loc.rbResolutionDone,
      ResolutionStatus.unknown => '',
    };
