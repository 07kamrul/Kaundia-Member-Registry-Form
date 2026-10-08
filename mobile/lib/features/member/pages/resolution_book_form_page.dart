import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/resolution_book_repository.dart';
import '../domain/resolution_book_entities.dart';
import '../presentation/bloc/resolution_book_form_bloc.dart';
import '../presentation/widgets/member_ui.dart';

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
    final submitting = state.status == ResolutionBookFormStatus.submitting;
    return PageBody(
      maxWidth: Breakpoints.formMaxWidth,
      children: [
        PageHeader(
          title: state.isEdit ? loc.rbFormEditTitle : loc.rbFormTitle,
          subtitle: loc.rbFormSubtitle,
          icon: state.isEdit ? Icons.edit_note : Icons.post_add,
        ),
        _MeetingInfoCard(state: state, bloc: bloc),
        _ResolutionsCard(state: state, bloc: bloc),
        if (state.submitAttempted && !state.formValid)
          NoticeBanner(tone: NoticeTone.error, message: loc.rbFormSubmitError),
        Gutter(
          vertical: 12,
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: loc.commonCancel,
                  variant: AppButtonVariant.secondary,
                  onPressed: submitting
                      ? null
                      : () => context.canPop() ? context.pop() : context.go('/resolution-book'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: submitting ? loc.commonLoading : loc.rbFormSave,
                  icon: Icons.save_outlined,
                  loading: submitting,
                  onPressed: () => bloc.add(const ResolutionBookFormSubmitted()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MeetingInfoCard extends StatelessWidget {
  const _MeetingInfoCard({required this.state, required this.bloc});

  final ResolutionBookFormState state;
  final ResolutionBookFormBloc bloc;

  void _change(ResolutionBookFormChanged event) => bloc.add(event);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppCard(
      title: loc.rbFormMeetingInfo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldGrid(children: _gridFields(loc)),
          const SizedBox(height: 12),
          SyncedTextField(
            label: loc.rbFormAgenda,
            value: state.agenda,
            maxLines: 5,
            onChanged: (v) => _change(ResolutionBookFormChanged(agenda: v)),
          ),
          const SizedBox(height: 12),
          SyncedTextField(
            label: loc.rbFormSummary,
            value: state.summary,
            maxLines: 6,
            onChanged: (v) => _change(ResolutionBookFormChanged(summary: v)),
          ),
          const SizedBox(height: 12),
          DatePickerField(
            label: loc.rbFormNextMeeting,
            value: state.nextMeetingDate,
            icon: Icons.event_repeat_outlined,
            onPicked: (v) => _change(ResolutionBookFormChanged(nextMeetingDate: v)),
          ),
        ],
      ),
    );
  }

  List<Widget> _gridFields(AppLocalizations loc) {
    return [
      SyncedTextField(
        label: loc.rbFormMeetingNo,
        value: state.meetingNo,
        icon: Icons.tag,
        onChanged: (v) => _change(ResolutionBookFormChanged(meetingNo: v)),
      ),
      DatePickerField(
        label: loc.rbFormDate,
        value: state.date,
        onPicked: (v) => _change(ResolutionBookFormChanged(date: v)),
      ),
      SyncedTextField(
        label: loc.rbFormTime,
        value: state.time,
        icon: Icons.schedule,
        keyboardType: TextInputType.datetime,
        onChanged: (v) => _change(ResolutionBookFormChanged(time: v)),
      ),
      DropdownButtonFormField<MeetingType>(
        initialValue: state.meetingType,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: loc.rbFormType,
          prefixIcon: const Icon(Icons.videocam_outlined),
        ),
        items: [
          DropdownMenuItem(value: MeetingType.online, child: Text(loc.rbTypeOnline)),
          DropdownMenuItem(value: MeetingType.offline, child: Text(loc.rbTypeOffline)),
        ],
        onChanged: (v) =>
            _change(ResolutionBookFormChanged(meetingType: v ?? MeetingType.offline)),
      ),
      SyncedTextField(
        label: loc.rbFormChairperson,
        value: state.chairperson,
        hint: loc.rbFormChairpersonPlaceholder,
        icon: Icons.person_outline,
        keyboardType: TextInputType.name,
        onChanged: (v) => _change(ResolutionBookFormChanged(chairperson: v)),
      ),
      DropdownButtonFormField<MeetingStatus>(
        initialValue: state.status_,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: loc.rbFormStatus,
          prefixIcon: const Icon(Icons.flag_outlined),
        ),
        items: [
          DropdownMenuItem(value: MeetingStatus.completed, child: Text(loc.rbStatusCompleted)),
          DropdownMenuItem(value: MeetingStatus.scheduled, child: Text(loc.rbStatusScheduled)),
          DropdownMenuItem(value: MeetingStatus.cancelled, child: Text(loc.rbStatusCancelled)),
        ],
        onChanged: (v) =>
            _change(ResolutionBookFormChanged(status: v ?? MeetingStatus.completed)),
      ),
    ];
  }
}

class _ResolutionsCard extends StatelessWidget {
  const _ResolutionsCard({required this.state, required this.bloc});

  final ResolutionBookFormState state;
  final ResolutionBookFormBloc bloc;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppCard(
      title: '${loc.rbFormResolutions} (${state.resolutions.length})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < state.resolutions.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _ResolutionEditor(index: i, state: state, bloc: bloc),
          ],
          AddItemButton(
            label: loc.rbFormAddResolution,
            onPressed: () => bloc.add(const ResolutionBookFormResolutionAdded()),
          ),
        ],
      ),
    );
  }
}

class _ResolutionEditor extends StatelessWidget {
  const _ResolutionEditor({required this.index, required this.state, required this.bloc});

  final int index;
  final ResolutionBookFormState state;
  final ResolutionBookFormBloc bloc;

  void _update(FormResolutionRow row) => bloc.add(ResolutionBookFormResolutionChanged(index, row));

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final row = state.resolutions[index];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.rbDetailResolutionNo(index + 1),
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
              IconButton(
                tooltip: loc.rbFormRemoveResolution,
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                onPressed: () => bloc.add(ResolutionBookFormResolutionRemoved(index)),
              ),
            ],
          ),
          SyncedTextField(
            label: loc.rbFormDecision,
            value: row.decision,
            maxLines: 3,
            errorText: state.submitAttempted && row.decision.trim().isEmpty
                ? loc.rbFormSubmitError
                : null,
            onChanged: (v) => _update(row.copyWith(decision: v)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _VoteField(
                  label: loc.rbVoteFor,
                  value: row.voteFor,
                  onChanged: (v) => _update(row.copyWith(voteFor: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VoteField(
                  label: loc.rbVoteAgainst,
                  value: row.voteAgainst,
                  onChanged: (v) => _update(row.copyWith(voteAgainst: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VoteField(
                  label: loc.rbVoteNeutral,
                  value: row.voteNeutral,
                  onChanged: (v) => _update(row.copyWith(voteNeutral: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SyncedTextField(
            label: loc.rbFormTask,
            value: row.task,
            icon: Icons.task_alt,
            textInputAction: TextInputAction.done,
            onChanged: (v) => _update(row.copyWith(task: v)),
          ),
        ],
      ),
    );
  }
}

/// Numeric vote input. Re-syncs from state only when the parsed number
/// differs, so clearing the field to retype doesn't snap back to "0".
class _VoteField extends StatefulWidget {
  const _VoteField({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_VoteField> createState() => _VoteFieldState();
}

class _VoteFieldState extends State<_VoteField> {
  late final TextEditingController _controller = TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(covariant _VoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((int.tryParse(_controller.text) ?? 0) != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: widget.label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      ),
      onChanged: (v) => widget.onChanged(int.tryParse(v) ?? 0),
    );
  }
}
