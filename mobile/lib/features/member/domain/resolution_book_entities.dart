import 'package:equatable/equatable.dart';

enum MeetingType { online, offline, unknown }

extension MeetingTypeX on MeetingType {
  static MeetingType fromName(String? name) =>
      name == 'online' ? MeetingType.online : MeetingType.offline;

  String get apiName => this == MeetingType.online ? 'online' : 'offline';
}

enum MeetingStatus { scheduled, completed, cancelled, unknown }

extension MeetingStatusX on MeetingStatus {
  static MeetingStatus fromName(String? name) => switch (name) {
        'scheduled' => MeetingStatus.scheduled,
        'completed' => MeetingStatus.completed,
        'cancelled' => MeetingStatus.cancelled,
        _ => MeetingStatus.unknown,
      };
}

enum ResolutionStatus { pending, inProgress, done, unknown }

extension ResolutionStatusX on ResolutionStatus {
  static ResolutionStatus fromName(String? name) => switch (name) {
        'pending' => ResolutionStatus.pending,
        'in_progress' => ResolutionStatus.inProgress,
        'done' => ResolutionStatus.done,
        _ => ResolutionStatus.unknown,
      };

  String get apiName => switch (this) {
        ResolutionStatus.pending => 'pending',
        ResolutionStatus.inProgress => 'in_progress',
        ResolutionStatus.done => 'done',
        ResolutionStatus.unknown => 'unknown',
      };
}

enum AttendanceStatus { present, absent, unknown }

extension AttendanceStatusX on AttendanceStatus {
  static AttendanceStatus fromName(String? name) =>
      name == 'present' ? AttendanceStatus.present : AttendanceStatus.absent;

  String get apiName => this == AttendanceStatus.present ? 'present' : 'absent';
}

enum RecordingType { video, audio, screenshot, chatLog, unknown }

extension RecordingTypeX on RecordingType {
  static RecordingType fromName(String? name) => switch (name) {
        'video' => RecordingType.video,
        'audio' => RecordingType.audio,
        'screenshot' => RecordingType.screenshot,
        'chat_log' => RecordingType.chatLog,
        _ => RecordingType.unknown,
      };
}

class MemberRef extends Equatable {
  const MemberRef({required this.id, required this.fullName, required this.memberId});

  final String id;
  final String fullName;
  final String? memberId;

  @override
  List<Object?> get props => [id, fullName, memberId];
}

class Resolution extends Equatable {
  const Resolution({
    required this.id,
    required this.meetingId,
    required this.resolutionNo,
    required this.decision,
    required this.voteFor,
    required this.voteAgainst,
    required this.voteNeutral,
    required this.assignedTo,
    required this.task,
    required this.dueDate,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String meetingId;
  final int resolutionNo;
  final String decision;
  final int voteFor;
  final int voteAgainst;
  final int voteNeutral;
  final MemberRef? assignedTo;
  final String? task;
  final String? dueDate;
  final ResolutionStatus status;
  final String? updatedAt;

  @override
  List<Object?> get props => [
        id, meetingId, resolutionNo, decision, voteFor, voteAgainst,
        voteNeutral, assignedTo, task, dueDate, status, updatedAt,
      ];
}

class AttendanceEntry extends Equatable {
  const AttendanceEntry({required this.member, required this.status});

  final MemberRef member;
  final AttendanceStatus status;

  @override
  List<Object?> get props => [member, status];
}

class Recording extends Equatable {
  const Recording({
    required this.id,
    required this.meetingId,
    required this.originalName,
    required this.fileType,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  final String id;
  final String meetingId;
  final String originalName;
  final RecordingType fileType;
  final int fileSize;
  final String? uploadedBy;
  final String? uploadedAt;

  @override
  List<Object?> get props => [
        id, meetingId, originalName, fileType, fileSize, uploadedBy, uploadedAt,
      ];
}

class MeetingListItem extends Equatable {
  const MeetingListItem({
    required this.id,
    required this.meetingNo,
    required this.date,
    required this.time,
    required this.meetingType,
    required this.chairperson,
    required this.nextMeetingDate,
    required this.status,
    required this.resolutionCount,
    required this.attendancePresent,
    required this.attendanceTotal,
    required this.attendancePercent,
  });

  final String id;
  final String meetingNo;
  final String date;
  final String? time;
  final MeetingType meetingType;
  final String chairperson;
  final String? nextMeetingDate;
  final MeetingStatus status;
  final int resolutionCount;
  final int attendancePresent;
  final int attendanceTotal;
  final num attendancePercent;

  @override
  List<Object?> get props => [
        id, meetingNo, date, time, meetingType, chairperson, nextMeetingDate,
        status, resolutionCount, attendancePresent, attendanceTotal,
        attendancePercent,
      ];
}

class MeetingDetail extends Equatable {
  const MeetingDetail({
    required this.id,
    required this.meetingNo,
    required this.date,
    required this.time,
    required this.meetingType,
    required this.chairperson,
    required this.nextMeetingDate,
    required this.status,
    required this.resolutionCount,
    required this.attendancePresent,
    required this.attendanceTotal,
    required this.attendancePercent,
    required this.agenda,
    required this.summary,
    required this.createdBy,
    required this.updatedAt,
    required this.resolutions,
    required this.attendance,
    required this.recordings,
  });

  final String id;
  final String meetingNo;
  final String date;
  final String? time;
  final MeetingType meetingType;
  final String chairperson;
  final String? nextMeetingDate;
  final MeetingStatus status;
  final int resolutionCount;
  final int attendancePresent;
  final int attendanceTotal;
  final num attendancePercent;
  final String agenda;
  final String? summary;
  final String? createdBy;
  final String? updatedAt;
  final List<Resolution> resolutions;
  final List<AttendanceEntry> attendance;
  final List<Recording> recordings;

  @override
  List<Object?> get props => [
        id, meetingNo, date, time, meetingType, chairperson, nextMeetingDate,
        status, resolutionCount, attendancePresent, attendanceTotal,
        attendancePercent, agenda, summary, createdBy, updatedAt, resolutions,
        attendance, recordings,
      ];
}

class MeetingPage extends Equatable {
  const MeetingPage({required this.total, required this.items});

  final int total;
  final List<MeetingListItem> items;

  @override
  List<Object?> get props => [total, items];
}

class MeetingSummary extends Equatable {
  const MeetingSummary({
    required this.totalMeetings,
    required this.meetingsThisYear,
    required this.averageAttendancePercent,
    required this.openActionItems,
    required this.upcomingMeetingDate,
    required this.recentMeetings,
  });

  final int totalMeetings;
  final int meetingsThisYear;
  final num averageAttendancePercent;
  final int openActionItems;
  final String? upcomingMeetingDate;
  final List<MeetingListItem> recentMeetings;

  @override
  List<Object?> get props => [
        totalMeetings, meetingsThisYear, averageAttendancePercent,
        openActionItems, upcomingMeetingDate, recentMeetings,
      ];
}

class ResolutionInput extends Equatable {
  const ResolutionInput({
    required this.decision,
    required this.voteFor,
    required this.voteAgainst,
    required this.voteNeutral,
    this.assignedToMemberId,
    this.task,
    this.dueDate,
    this.status,
  });

  final String decision;
  final int voteFor;
  final int voteAgainst;
  final int voteNeutral;
  final String? assignedToMemberId;
  final String? task;
  final String? dueDate;
  final ResolutionStatus? status;

  @override
  List<Object?> get props => [
        decision, voteFor, voteAgainst, voteNeutral, assignedToMemberId, task,
        dueDate, status,
      ];
}

class AttendanceInput extends Equatable {
  const AttendanceInput({required this.memberId, required this.status});

  final String memberId;
  final AttendanceStatus status;

  @override
  List<Object?> get props => [memberId, status];
}

class MeetingCreateInput extends Equatable {
  const MeetingCreateInput({
    this.meetingNo,
    required this.date,
    this.time,
    required this.meetingType,
    required this.chairperson,
    required this.agenda,
    this.summary,
    this.nextMeetingDate,
    this.status,
    required this.resolutions,
    required this.attendance,
    this.notify = true,
  });

  final String? meetingNo;
  final String date;
  final String? time;
  final MeetingType meetingType;
  final String chairperson;
  final String agenda;
  final String? summary;
  final String? nextMeetingDate;
  final MeetingStatus? status;
  final List<ResolutionInput> resolutions;
  final List<AttendanceInput> attendance;
  final bool notify;

  @override
  List<Object?> get props => [
        meetingNo, date, time, meetingType, chairperson, agenda, summary,
        nextMeetingDate, status, resolutions, attendance, notify,
      ];
}
