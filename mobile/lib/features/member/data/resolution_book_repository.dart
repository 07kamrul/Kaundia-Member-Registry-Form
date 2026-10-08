import '../../../core/network/api_client.dart';
import '../domain/resolution_book_entities.dart';

String _str(dynamic v) => v?.toString() ?? '';
String? _s(dynamic v) => v?.toString();
int _int(dynamic v) => (v is num) ? v.toInt() : 0;
num _num(dynamic v) => (v is num) ? v : 0;

MemberRef? _memberRef(Map<dynamic, dynamic>? api) => api == null
    ? null
    : MemberRef(id: _str(api['id']), fullName: _str(api['full_name']), memberId: _s(api['member_id']));

Resolution resolutionFromApi(Map<dynamic, dynamic> api) => Resolution(
      id: _str(api['id']),
      meetingId: _str(api['meeting_id']),
      resolutionNo: _int(api['resolution_no']),
      decision: _str(api['decision']),
      voteFor: _int(api['vote_for']),
      voteAgainst: _int(api['vote_against']),
      voteNeutral: _int(api['vote_neutral']),
      assignedTo: _memberRef(api['assigned_to'] as Map<dynamic, dynamic>?),
      task: _s(api['task']),
      dueDate: _s(api['due_date']),
      status: ResolutionStatusX.fromName(_s(api['status'])),
      updatedAt: _s(api['updated_at']),
    );

Recording _recording(Map<dynamic, dynamic> api) => Recording(
      id: _str(api['id']),
      meetingId: _str(api['meeting_id']),
      originalName: _str(api['original_name']),
      fileType: RecordingTypeX.fromName(_s(api['file_type'])),
      fileSize: _int(api['file_size']),
      uploadedBy: _s(api['uploaded_by']),
      uploadedAt: _s(api['uploaded_at']),
    );

MeetingListItem meetingListItemFromApi(Map<dynamic, dynamic> api) => MeetingListItem(
      id: _str(api['id']),
      meetingNo: _str(api['meeting_no']),
      date: _str(api['date']),
      time: _s(api['time']),
      meetingType: MeetingTypeX.fromName(_s(api['meeting_type'])),
      chairperson: _str(api['chairperson']),
      nextMeetingDate: _s(api['next_meeting_date']),
      status: MeetingStatusX.fromName(_s(api['status'])),
      resolutionCount: _int(api['resolution_count']),
      attendancePresent: _int(api['attendance_present']),
      attendanceTotal: _int(api['attendance_total']),
      attendancePercent: _num(api['attendance_percent']),
    );

MeetingDetail meetingDetailFromApi(Map<dynamic, dynamic> api) {
  final base = meetingListItemFromApi(api);
  return MeetingDetail(
    id: base.id,
    meetingNo: base.meetingNo,
    date: base.date,
    time: base.time,
    meetingType: base.meetingType,
    chairperson: base.chairperson,
    nextMeetingDate: base.nextMeetingDate,
    status: base.status,
    resolutionCount: base.resolutionCount,
    attendancePresent: base.attendancePresent,
    attendanceTotal: base.attendanceTotal,
    attendancePercent: base.attendancePercent,
    agenda: _str(api['agenda']),
    summary: _s(api['summary']),
    createdBy: _s(api['created_by']),
    updatedAt: _s(api['updated_at']),
    resolutions: [
      for (final r in (api['resolutions'] as List<dynamic>? ?? const []))
        resolutionFromApi(r as Map<dynamic, dynamic>),
    ],
    attendance: [
      for (final a in (api['attendance'] as List<dynamic>? ?? const []))
        AttendanceEntry(
          member: _memberRef((a as Map<dynamic, dynamic>)['member'] as Map<dynamic, dynamic>)!,
          status: AttendanceStatusX.fromName(_s(a['status'])),
        ),
    ],
    recordings: [
      for (final r in (api['recordings'] as List<dynamic>? ?? const []))
        _recording(r as Map<dynamic, dynamic>),
    ],
  );
}

/// Public resolution-book reads + manage_resolution_book writes
/// (resolution-book.service.ts).
class ResolutionBookRepository {
  ResolutionBookRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<MeetingPage> listMeetings({
    String? q,
    String? meetingType,
    String? meetingStatus,
    String? dateFrom,
    String? dateTo,
    int limit = 10,
    int offset = 0,
  }) async {
    final query = <String, String>{
      if (q != null && q.isNotEmpty) 'q': q,
      if (meetingType != null && meetingType.isNotEmpty) 'meeting_type': meetingType,
      if (meetingStatus != null && meetingStatus.isNotEmpty) 'meeting_status': meetingStatus,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
      'limit': '$limit',
      'offset': '$offset',
    };
    final api = await _api.getUri('/resolution-book/meetings', query: query)
        as Map<dynamic, dynamic>;
    return MeetingPage(
      total: _int(api['total']),
      items: [
        for (final row in (api['items'] as List<dynamic>? ?? const []))
          meetingListItemFromApi(row as Map<dynamic, dynamic>),
      ],
    );
  }

  Future<MeetingSummary> summary() async {
    final api = await _api.getUri('/resolution-book/summary') as Map<dynamic, dynamic>;
    return meetingSummaryFromApi(api);
  }

  Future<SuggestedMeetingNo> suggestMeetingNo(String forDate) async {
    final api = await _api.getUri('/resolution-book/meetings/suggest-no',
        query: {'for_date': forDate}) as Map<dynamic, dynamic>;
    return SuggestedMeetingNo(
      meetingNo: _str(api['meeting_no']),
      available: api['available'] == true,
    );
  }

  Future<MeetingDetail> getMeeting(String id) async {
    final api = await _api.getUri('/resolution-book/meetings/$id') as Map<dynamic, dynamic>;
    return meetingDetailFromApi(api);
  }

  Future<MeetingDetail> createMeeting(MeetingCreateInput input) async {
    final data = await _api.post('/resolution-book/meetings', _meetingBody(input))
        as Map<dynamic, dynamic>;
    return meetingDetailFromApi(data);
  }

  Future<MeetingDetail> updateMeeting(String id, MeetingCreateInput input) async {
    final data = await _api.put('/resolution-book/meetings/$id', _meetingBody(input))
        as Map<dynamic, dynamic>;
    return meetingDetailFromApi(data);
  }

  Future<Resolution> updateResolutionStatus(String id, ResolutionStatus status) async {
    final data = await _api.put('/resolution-book/resolutions/$id',
        {'status': status.apiName}) as Map<dynamic, dynamic>;
    return resolutionFromApi((data['resolution'] as Map<dynamic, dynamic>? ?? data));
  }

  /// Server-rendered official minutes (GET .../export.pdf).
  Future<List<int>> downloadPdf(String meetingId) =>
      _api.downloadBytes('/resolution-book/meetings/$meetingId/export.pdf');

  Map<String, dynamic> _meetingBody(MeetingCreateInput input) => {
        'meeting_no': (input.meetingNo ?? '').isEmpty ? null : input.meetingNo,
        'date': input.date,
        'time': (input.time ?? '').isEmpty ? null : input.time,
        'meeting_type': input.meetingType.apiName,
        'chairperson': input.chairperson,
        'chairperson_member_id': null,
        'agenda': input.agenda,
        'summary': (input.summary ?? '').isEmpty ? null : input.summary,
        'next_meeting_date': (input.nextMeetingDate ?? '').isEmpty ? null : input.nextMeetingDate,
        'status': (input.status ?? MeetingStatus.completed).apiName,
        'resolutions': [
          for (final r in input.resolutions)
            {
              'decision': r.decision,
              'vote_for': r.voteFor,
              'vote_against': r.voteAgainst,
              'vote_neutral': r.voteNeutral,
              'assigned_to_member_id': (r.assignedToMemberId ?? '').isEmpty ? null : r.assignedToMemberId,
              'task': (r.task ?? '').isEmpty ? null : r.task,
              'due_date': (r.dueDate ?? '').isEmpty ? null : r.dueDate,
              'status': (r.status ?? ResolutionStatus.pending).apiName,
            },
        ],
        'attendance': [
          for (final a in input.attendance)
            {'member_id': a.memberId, 'status': a.status.apiName},
        ],
        'notify': input.notify,
      };
}

MeetingSummary meetingSummaryFromApi(Map<dynamic, dynamic> api) => MeetingSummary(
      totalMeetings: _int(api['total_meetings']),
      meetingsThisYear: _int(api['meetings_this_year']),
      averageAttendancePercent: _num(api['average_attendance_percent']),
      openActionItems: _int(api['open_action_items']),
      upcomingMeetingDate: _s(api['upcoming_meeting_date']),
      recentMeetings: [
        for (final row in (api['recent_meetings'] as List<dynamic>? ?? const []))
          meetingListItemFromApi(row as Map<dynamic, dynamic>),
      ],
    );

class SuggestedMeetingNo {
  const SuggestedMeetingNo({required this.meetingNo, required this.available});

  final String meetingNo;
  final bool available;
}
