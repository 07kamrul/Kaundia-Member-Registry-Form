import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/resolution_book_repository.dart';
import '../domain/resolution_book_entities.dart';
import '../presentation/bloc/resolution_book_form_bloc.dart';

/// Port of Angular MeetingFormComponent (reachable only with
/// manage_resolution_book, enforced by the router guards): meeting core
/// fields + resolution rows, create and edit.
class ResolutionBookFormPage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const ResolutionBookFormPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ResolutionBookFormBloc(
        repository: ResolutionBookRepository(apiClient: sl<ApiClient>()),
      )..add(ResolutionBookFormInitialized(editId: id)),
      child: const _FormView(),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocConsumer<ResolutionBookFormBloc, ResolutionBookFormState>(
        listener: (context, state) {
          if (state.status == ResolutionBookFormStatus.success) {
            showAppToast(context, loc.rbFormSubmit);
            context.go('/resolution-book');
          }
          final error = state.submitError;
          if (error != null) {
            showAppToast(context,
                error == 'submitError' ? loc.rbFormSubmitError : error,
                error: true);
          }
        },
        builder: (context, state) {
          final bloc = context.read<ResolutionBookFormBloc>();
          return switch (state.status) {
            ResolutionBookFormStatus.idle ||
            ResolutionBookFormStatus.loading =>
              const SkeletonLoader(lines: 6),
            ResolutionBookFormStatus.failure => InlineError(
                message: loc.rbLoadError,
                onRetry: () => bloc.add(ResolutionBookFormInitialized(editId: state.editId)),
              ),
            _ => _form(context, state, loc, bloc),
          };
        },
      ),
    );
  }

  Widget _form(
    BuildContext context,
    ResolutionBookFormState state,
    AppLocalizations loc,
    ResolutionBookFormBloc bloc,
  ) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        PageHeader(
          title: state.isEdit ? loc.rbFormEditTitle : loc.rbFormTitle,
          subtitle: loc.rbFormSubtitle,
        ),
        AppCard(
          title: loc.rbFormMeetingInfo,
          child: Column(
            children: [
              _text(
                label: loc.rbFormMeetingNo,
                value: state.meetingNo,
                onChanged: (v) => bloc.add(ResolutionBookFormChanged(meetingNo: v)),
              ),
              _dateField(
                context,
                label: loc.rbFormDate,
                value: state.date,
                onPicked: (v) => bloc.add(ResolutionBookFormChanged(date: v)),
              ),
              _text(
                label: loc.rbFormTime,
                value: state.time,
                onChanged: (v) => bloc.add(ResolutionBookFormChanged(time: v)),
              ),
              DropdownButtonFormField<MeetingType>(
                initialValue: state.meetingType,
                decoration: InputDecoration(
                    labelText: loc.rbFormType, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: MeetingType.online, child: Text(loc.rbTypeOnline)),
                  DropdownMenuItem(value: MeetingType.offline, child: Text(loc.rbTypeOffline)),
                ],
                onChanged: (v) =>
                    bloc.add(ResolutionBookFormChanged(meetingType: v ?? MeetingType.offline)),
              ),
              const SizedBox(height: 10),
              _text(
                label: loc.rbFormChairperson,
                value: state.chairperson,
                hint: loc.rbFormChairpersonPlaceholder,
                onChanged: (v) => bloc.add(ResolutionBookFormChanged(chairperson: v)),
              ),
              _text(
                label: loc.rbFormAgenda,
                value: state.agenda,
                maxLines: 3,
                onChanged: (v) => bloc.add(ResolutionBookFormChanged(agenda: v)),
              ),
              _text(
                label: loc.rbFormSummary,
                value: state.summary,
                maxLines: 3,
                onChanged: (v) => bloc.add(ResolutionBookFormChanged(summary: v)),
              ),
              _dateField(
                context,
                label: loc.rbFormNextMeeting,
                value: state.nextMeetingDate,
                onPicked: (v) => bloc.add(ResolutionBookFormChanged(nextMeetingDate: v)),
              ),
              DropdownButtonFormField<MeetingStatus>(
                initialValue: state.status_,
                decoration: InputDecoration(
                    labelText: loc.rbFormStatus, border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: MeetingStatus.completed, child: Text(loc.rbStatusCompleted)),
                  DropdownMenuItem(value: MeetingStatus.scheduled, child: Text(loc.rbStatusScheduled)),
                  DropdownMenuItem(value: MeetingStatus.cancelled, child: Text(loc.rbStatusCancelled)),
                ],
                onChanged: (v) =>
                    bloc.add(ResolutionBookFormChanged(status: v ?? MeetingStatus.completed)),
              ),
            ].expand((w) sync* {
              yield w;
              yield const SizedBox(height: 10);
            }).toList(),
          ),
        ),
        AppCard(
          title: loc.rbFormResolutions,
          trailing: IconButton(
            tooltip: loc.rbFormAddResolution,
            icon: const Icon(Icons.add),
            onPressed: () => bloc.add(const ResolutionBookFormResolutionAdded()),
          ),
          child: state.resolutions.isEmpty
              ? Text(loc.rbFormAddResolution)
              : Column(
                  children: [
                    for (var i = 0; i < state.resolutions.length; i++)
                      _resolutionCard(context, bloc, state, i, loc),
                  ],
                ),
        ),
        if (state.submitAttempted && !state.formValid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              loc.rbFormSubmitError,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppButton(
            label: state.status == ResolutionBookFormStatus.submitting
                ? loc.commonLoading
                : loc.rbFormSave,
            expanded: true,
            onPressed: state.status == ResolutionBookFormStatus.submitting
                ? null
                : () => bloc.add(const ResolutionBookFormSubmitted()),
          ),
        ),
      ],
    );
  }

  Widget _resolutionCard(
    BuildContext context,
    ResolutionBookFormBloc bloc,
    ResolutionBookFormState state,
    int index,
    AppLocalizations loc,
  ) {
    final row = state.resolutions[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('${loc.rbDetailResolutionNo} ${index + 1}')),
                IconButton(
                  tooltip: loc.rbFormRemoveResolution,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      bloc.add(ResolutionBookFormResolutionRemoved(index)),
                ),
              ],
            ),
            TextField(
              decoration: InputDecoration(
                labelText: loc.rbFormDecision,
                border: const OutlineInputBorder(),
                errorText: state.submitAttempted && row.decision.trim().isEmpty
                    ? loc.rbFormSubmitError
                    : null,
              ),
              onChanged: (v) => bloc
                  .add(ResolutionBookFormResolutionChanged(index, row.copyWith(decision: v))),
            ),
            Row(
              children: [
                _voteField(context, loc.rbVoteFor, row.voteFor,
                    (v) => bloc.add(ResolutionBookFormResolutionChanged(index, row.copyWith(voteFor: v)))),
                _voteField(context, loc.rbVoteAgainst, row.voteAgainst,
                    (v) => bloc.add(ResolutionBookFormResolutionChanged(index, row.copyWith(voteAgainst: v)))),
                _voteField(context, loc.rbVoteNeutral, row.voteNeutral,
                    (v) => bloc.add(ResolutionBookFormResolutionChanged(index, row.copyWith(voteNeutral: v)))),
              ],
            ),
            TextField(
              decoration: InputDecoration(
                labelText: loc.rbFormTask,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) =>
                  bloc.add(ResolutionBookFormResolutionChanged(index, row.copyWith(task: v))),
            ),
          ].expand((w) sync* {
            yield w;
            yield const SizedBox(height: 10);
          }).toList(),
        ),
      ),
    );
  }

  Widget _voteField(BuildContext context, String label, int value, ValueChanged<int> onChanged) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: TextFormField(
          initialValue: '$value',
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
        ),
      ),
    );
  }

  Widget _text({
    required String label,
    required String value,
    String? hint,
    int maxLines = 1,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: TextEditingController(text: value),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }

  Widget _dateField(
    BuildContext context, {
    required String label,
    required String value,
    required ValueChanged<String> onPicked,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            controller: TextEditingController(text: value),
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDate: DateTime.tryParse(value) ?? DateTime.now(),
              );
              if (picked != null) {
                onPicked(picked.toIso8601String().substring(0, 10));
              }
            },
          ),
        ),
      ],
    );
  }
}
