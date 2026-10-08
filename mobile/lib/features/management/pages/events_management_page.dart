import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/bloc_actions.dart';
import '../presentation/bloc/events_bloc.dart';
import '../presentation/widgets/content_management_widgets.dart';
import '../presentation/widgets/management_page_kit.dart';
import '../presentation/widgets/management_widgets.dart';
import 'notices_management_page.dart' show datetimeParts, isoFromParts;

/// Events management (Angular events): status/category filters, CRUD,
/// publish toggle, delete with confirm.
class EventsManagementPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const EventsManagementPage(
      {super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<EventsManagementPage> createState() => _EventsManagementPageState();
}

class _EventsManagementPageState extends State<EventsManagementPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) =>
          EventsBloc(repository: AdminRepository(apiClient: sl<ApiClient>()))
            ..add(const EventsInitRequested()),
      child: BlocConsumer<EventsBloc, ContentListState<EventItem>>(
        listenWhen: (a, b) => a.saveError != b.saveError,
        listener: (context, state) {
          if (state.saveError != null) {
            showAppToast(context, loc.adminEventsErrorsSaveFailed, error: true);
          }
        },
        builder: (context, state) => _buildScaffold(context, state),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, ContentListState<EventItem> state) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<EventsBloc>();
    return Scaffold(
      floatingActionButton: AddFab(
        label: loc.adminEventsCreate,
        onPressed: () => _openForm(context, bloc),
      ),
      body: PageBody(
        padding: const EdgeInsets.only(bottom: kFabClearance),
        onRefresh: () => reloadAndWait<EventsEvent, ContentListState<EventItem>>(
          bloc,
          const EventsLoadRequested(),
          (s) => s.loading,
        ),
        children: [
          PageHeader(
            icon: Icons.event_outlined,
            title: loc.adminEventsTitle,
            subtitle: loc.adminEventsSubtitle,
          ),
          ContentFilterBar(
            statusLabels: [
              loc.adminEventsFiltersAll,
              loc.adminEventsFiltersPublished,
              loc.adminEventsFiltersDraft,
            ],
            publishedFilter: state.publishedFilter,
            onStatusChanged: (i) => bloc.add(EventsStatusFilterChanged(i)),
            categoryLabel: loc.adminEventsFiltersCategory,
            allCategoriesLabel: loc.adminEventsFiltersAllCategories,
            categories: state.categories,
            categoryFilter: state.categoryFilter,
            onCategoryChanged: (id) => bloc.add(EventsCategoryFilterChanged(id)),
          ),
          ..._list(context, state, bloc),
        ],
      ),
    );
  }

  List<Widget> _list(BuildContext context, ContentListState<EventItem> state,
      EventsBloc bloc) {
    final loc = AppLocalizations.of(context);
    if (state.loading && state.items.isEmpty) return const [SkeletonLoader(lines: 4)];
    if (state.error != null && state.items.isEmpty) {
      return [
        InlineError(
          message: loc.adminEventsErrorsLoadFailed,
          onRetry: () => bloc.add(const EventsLoadRequested()),
        ),
      ];
    }
    if (state.items.isEmpty) {
      return [
        ContentEmptyState(
          icon: Icons.event_outlined,
          message: loc.adminEventsNoItems,
          helper: loc.adminEventsEmptyHelper,
          actionLabel: loc.adminEventsCreateFirst,
          onCreate: () => _openForm(context, bloc),
        ),
      ];
    }
    return [
      ReloadingBar(visible: state.loading),
      CardGrid(
        children: [
          for (final e in state.items) _card(context, state, bloc, e),
        ],
      ),
    ];
  }

  Widget _card(BuildContext context, ContentListState<EventItem> state,
      EventsBloc bloc, EventItem e) {
    final loc = AppLocalizations.of(context);
    final (startDate, startTime) = datetimeParts(e.startAt);
    final (endDate, endTime) = datetimeParts(e.endAt);
    final when = endDate.isEmpty
        ? '$startDate $startTime'
        : '$startDate $startTime → $endDate $endTime';
    return ContentItemCard(
      key: ValueKey(e.id),
      title: e.title,
      preview: e.description,
      statusLabel:
          e.isPublished ? loc.adminEventsStatusPublished : loc.adminEventsStatusDraft,
      published: e.isPublished,
      metas: [
        (Icons.schedule_rounded, when),
        if (e.location != null && e.location!.isNotEmpty)
          (Icons.place_outlined, e.location!),
        (Icons.sell_outlined, contentCategoryLabel(state.categories, e.categoryId)),
      ],
      membersOnlyLabel: e.isMembersOnly ? loc.adminEventsMembersOnlyBadge : null,
      publishLabel: e.isPublished ? loc.adminEventsUnpublish : loc.adminEventsPublish,
      busy: state.busyId == e.id,
      onTogglePublish: () => bloc.add(EventPublishToggled(e)),
      onEdit: () => _openForm(context, bloc, editing: e),
      onDelete: () => _delete(context, bloc, e),
    );
  }

  Future<void> _delete(BuildContext context, EventsBloc bloc, EventItem e) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await confirmDialog(
      context,
      title: loc.adminEventsDeleteModalTitle,
      message: '${e.title}\n\n${loc.adminEventsDeleteModalMessageSuffix}',
      confirmLabel: loc.adminEventsDeleteModalConfirmLabel,
      destructive: true,
    );
    if (confirmed && context.mounted) bloc.add(EventDeleteRequested(e));
  }

  Future<void> _openForm(BuildContext context, EventsBloc bloc,
      {EventItem? editing}) async {
    final saved = await showFormSheet<bool>(
      context,
      builder: (_) => _EventForm(bloc: bloc, editing: editing),
    );
    if (saved == true && context.mounted) {
      showAppToast(context, AppLocalizations.of(context).commonSave);
    }
  }
}

class _EventForm extends StatefulWidget {
  const _EventForm({required this.bloc, this.editing});

  final EventsBloc bloc;
  final EventItem? editing;

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  late final _title = TextEditingController(text: widget.editing?.title ?? '');
  late final _description =
      TextEditingController(text: widget.editing?.description ?? '');
  late final _location = TextEditingController(text: widget.editing?.location ?? '');
  late String _categoryId = widget.editing?.categoryId ?? '';
  late String _startDate = datetimeParts(widget.editing?.startAt).$1;
  late String _startTime = datetimeParts(widget.editing?.startAt).$2;
  late String _endDate = datetimeParts(widget.editing?.endAt).$1;
  late String _endTime = datetimeParts(widget.editing?.endAt).$2;
  late bool _published = widget.editing?.isPublished ?? false;
  late bool _membersOnly = widget.editing?.isMembersOnly ?? false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final categories = widget.bloc.state.categories;
    return FormSheet(
      icon: Icons.event_outlined,
      title: widget.editing == null
          ? loc.adminEventsFormCreateTitle
          : loc.adminEventsFormEditTitle,
      actions: [
        AppButton(
          label: widget.editing == null ? loc.adminEventsFormCreate : loc.commonSave,
          loading: _saving,
          onPressed: _title.text.trim().isEmpty ? null : _save,
        ),
      ],
      children: [
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: loc.adminEventsFormTitle),
        ),
        TextField(
          controller: _description,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: loc.adminEventsFormDescription,
            alignLabelWithHint: true,
          ),
        ),
        TextField(
          controller: _location,
          decoration: InputDecoration(
            labelText: loc.adminEventsFormLocation,
            prefixIcon: const Icon(Icons.place_outlined),
          ),
        ),
        LabeledDropdown<String>(
          label: loc.adminEventsFormCategory,
          value: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
          prefixIcon: Icons.sell_outlined,
          options: [
            (null, loc.adminEventsFormNoCategory),
            for (final c in categories) (c.id, c.label),
          ],
          onChanged: (v) => setState(() => _categoryId = v ?? ''),
        ),
        DateTimeFields(
          label: loc.adminEventsFormStartAt,
          date: _startDate,
          time: _startTime,
          onDateChanged: (v) => setState(() {
            _startDate = v;
            _error = null;
          }),
          onTimeChanged: (v) => setState(() => _startTime = v),
        ),
        DateTimeFields(
          label: loc.adminEventsFormEndAt,
          date: _endDate,
          time: _endTime,
          onDateChanged: (v) => setState(() {
            _endDate = v;
            _error = null;
          }),
          onTimeChanged: (v) => setState(() {
            _endTime = v;
            _error = null;
          }),
        ),
        if (_error != null)
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _published,
          title: Text(loc.adminEventsFormPublished),
          onChanged: (v) => setState(() => _published = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _membersOnly,
          title: Text(loc.adminEventsFormMembersOnly),
          onChanged: (v) => setState(() => _membersOnly = v),
        ),
      ],
    );
  }

  String? _validate(AppLocalizations loc, String startAt, String? endAt) {
    if (_startDate.isEmpty) return loc.adminEventsFormStartAtRequired;
    if (endAt != null && !DateTime.parse(endAt).isAfter(DateTime.parse(startAt))) {
      return loc.adminEventsFormEndBeforeStart;
    }
    return null;
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    final startAt = isoFromParts(_startDate, _startTime);
    final endAt = _endDate.isEmpty ? null : isoFromParts(_endDate, _endTime);
    final error = _validate(loc, startAt, endAt);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    setState(() => _saving = true);
    final ok = await dispatchForBool(
      widget.bloc,
      (c) => EventSaveRequested(
        completer: c,
        editingId: widget.editing?.id,
        payload: EventInput(
          title: _title.text.trim(),
          description: optional(_description),
          location: optional(_location),
          categoryId: _categoryId.isEmpty ? null : _categoryId,
          startAt: startAt,
          endAt: endAt,
          isPublished: _published,
          isMembersOnly: _membersOnly,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }
}
