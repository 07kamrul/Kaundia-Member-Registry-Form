import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/bloc_actions.dart';
import '../presentation/bloc/notices_bloc.dart';
import '../presentation/widgets/content_management_widgets.dart';
import '../presentation/widgets/management_page_kit.dart';
import '../presentation/widgets/management_widgets.dart';

/// ISO instant -> local "yyyy-MM-ddTHH:mm" (Angular toDatetimeLocal).
(String, String) datetimeParts(String? iso) {
  final parsed = DateTime.tryParse(iso ?? '')?.toLocal();
  if (parsed == null) return ('', '');
  return (
    DateFormat('yyyy-MM-dd').format(parsed),
    DateFormat('HH:mm').format(parsed),
  );
}

/// Local wall-clock "yyyy-MM-ddTHH:mm" -> UTC ISO (Angular toIso).
String isoFromParts(String date, String time) {
  if (date.isEmpty) return '';
  final parsed = DateTime.parse('${date}T${time.isEmpty ? '00:00' : time}');
  return parsed.toUtc().toIso8601String();
}

/// Notices management (Angular notices): status/category filters, CRUD,
/// publish toggle, delete with confirm.
class NoticesManagementPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const NoticesManagementPage(
      {super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<NoticesManagementPage> createState() => _NoticesManagementPageState();
}

class _NoticesManagementPageState extends State<NoticesManagementPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) =>
          NoticesBloc(repository: AdminRepository(apiClient: sl<ApiClient>()))
            ..add(const NoticesInitRequested()),
      child: BlocConsumer<NoticesBloc, ContentListState<Notice>>(
        listenWhen: (a, b) => a.saveError != b.saveError,
        listener: (context, state) {
          if (state.saveError != null) {
            showAppToast(context, loc.adminNoticesErrorsSaveFailed, error: true);
          }
        },
        builder: (context, state) => _buildScaffold(context, state),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, ContentListState<Notice> state) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<NoticesBloc>();
    return Scaffold(
      floatingActionButton: AddFab(
        label: loc.adminNoticesCreate,
        onPressed: () => _openForm(context, bloc),
      ),
      body: PageBody(
        padding: const EdgeInsets.only(bottom: kFabClearance),
        onRefresh: () => reloadAndWait<NoticesEvent, ContentListState<Notice>>(
          bloc,
          const NoticesLoadRequested(),
          (s) => s.loading,
        ),
        children: [
          PageHeader(
            icon: Icons.campaign_outlined,
            title: loc.adminNoticesTitle,
            subtitle: loc.adminNoticesSubtitle,
          ),
          ContentFilterBar(
            statusLabels: [
              loc.adminNoticesFiltersAll,
              loc.adminNoticesFiltersPublished,
              loc.adminNoticesFiltersDraft,
            ],
            publishedFilter: state.publishedFilter,
            onStatusChanged: (i) => bloc.add(NoticesStatusFilterChanged(i)),
            categoryLabel: loc.adminNoticesFiltersCategory,
            allCategoriesLabel: loc.adminNoticesFiltersAllCategories,
            categories: state.categories,
            categoryFilter: state.categoryFilter,
            onCategoryChanged: (id) => bloc.add(NoticesCategoryFilterChanged(id)),
          ),
          ..._list(context, state, bloc),
        ],
      ),
    );
  }

  List<Widget> _list(
      BuildContext context, ContentListState<Notice> state, NoticesBloc bloc) {
    final loc = AppLocalizations.of(context);
    if (state.loading && state.items.isEmpty) return const [SkeletonLoader(lines: 4)];
    if (state.error != null && state.items.isEmpty) {
      return [
        InlineError(
          message: loc.adminNoticesErrorsLoadFailed,
          onRetry: () => bloc.add(const NoticesLoadRequested()),
        ),
      ];
    }
    if (state.items.isEmpty) {
      return [
        ContentEmptyState(
          icon: Icons.campaign_outlined,
          message: loc.adminNoticesNoItems,
          helper: loc.adminNoticesEmptyHelper,
          actionLabel: loc.adminNoticesCreateFirst,
          onCreate: () => _openForm(context, bloc),
        ),
      ];
    }
    return [
      ReloadingBar(visible: state.loading),
      CardGrid(
        children: [
          for (final n in state.items) _card(context, state, bloc, n),
        ],
      ),
    ];
  }

  String _statusLabel(AppLocalizations loc, Notice n) {
    if (!n.isPublished) return loc.adminNoticesStatusDraft;
    final publishAt = DateTime.tryParse(n.publishAt ?? '');
    if (publishAt != null && publishAt.isAfter(DateTime.now())) {
      return loc.adminNoticesStatusScheduled;
    }
    return loc.adminNoticesStatusPublished;
  }

  Widget _card(BuildContext context, ContentListState<Notice> state,
      NoticesBloc bloc, Notice n) {
    final loc = AppLocalizations.of(context);
    final (date, time) = datetimeParts(n.publishAt);
    return ContentItemCard(
      key: ValueKey(n.id),
      title: n.title,
      preview: n.body,
      statusLabel: _statusLabel(loc, n),
      published: n.isPublished,
      metas: [
        (Icons.sell_outlined, contentCategoryLabel(state.categories, n.categoryId)),
        if (date.isNotEmpty) (Icons.schedule_rounded, '$date $time'),
      ],
      membersOnlyLabel: n.isMembersOnly ? loc.adminNoticesMembersOnlyBadge : null,
      publishLabel: n.isPublished ? loc.adminNoticesUnpublish : loc.adminNoticesPublish,
      busy: state.busyId == n.id,
      onTogglePublish: () => bloc.add(NoticePublishToggled(n)),
      onEdit: () => _openForm(context, bloc, editing: n),
      onDelete: () => _delete(context, bloc, n),
    );
  }

  Future<void> _delete(BuildContext context, NoticesBloc bloc, Notice n) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await confirmDialog(
      context,
      title: loc.adminNoticesDeleteModalTitle,
      message: '${n.title}\n\n${loc.adminNoticesDeleteModalMessageSuffix}',
      confirmLabel: loc.adminNoticesDeleteModalConfirmLabel,
      destructive: true,
    );
    if (confirmed && context.mounted) bloc.add(NoticeDeleteRequested(n));
  }

  Future<void> _openForm(BuildContext context, NoticesBloc bloc,
      {Notice? editing}) async {
    final saved = await showFormSheet<bool>(
      context,
      builder: (_) => _NoticeForm(bloc: bloc, editing: editing),
    );
    if (saved == true && context.mounted) {
      showAppToast(context, AppLocalizations.of(context).commonSave);
    }
  }
}

class _NoticeForm extends StatefulWidget {
  const _NoticeForm({required this.bloc, this.editing});

  final NoticesBloc bloc;
  final Notice? editing;

  @override
  State<_NoticeForm> createState() => _NoticeFormState();
}

class _NoticeFormState extends State<_NoticeForm> {
  late final _title = TextEditingController(text: widget.editing?.title ?? '');
  late final _body = TextEditingController(text: widget.editing?.body ?? '');
  late String _categoryId = widget.editing?.categoryId ?? '';
  late String _publishDate = datetimeParts(widget.editing?.publishAt).$1;
  late String _publishTime = datetimeParts(widget.editing?.publishAt).$2;
  late bool _published = widget.editing?.isPublished ?? false;
  late bool _membersOnly = widget.editing?.isMembersOnly ?? false;
  bool _saving = false;

  bool get _canSave =>
      _title.text.trim().isNotEmpty && _body.text.trim().isNotEmpty;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final categories = widget.bloc.state.categories;
    return FormSheet(
      icon: Icons.campaign_outlined,
      title: widget.editing == null
          ? loc.adminNoticesFormCreateTitle
          : loc.adminNoticesFormEditTitle,
      actions: [
        AppButton(
          label: widget.editing == null ? loc.adminNoticesFormCreate : loc.commonSave,
          loading: _saving,
          onPressed: _canSave ? _save : null,
        ),
      ],
      children: [
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: loc.adminNoticesFormTitle),
        ),
        TextField(
          controller: _body,
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: loc.adminNoticesFormBody,
            alignLabelWithHint: true,
          ),
        ),
        LabeledDropdown<String>(
          label: loc.adminNoticesFormCategory,
          value: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
          prefixIcon: Icons.sell_outlined,
          options: [
            (null, loc.adminNoticesFormNoCategory),
            for (final c in categories) (c.id, c.label),
          ],
          onChanged: (v) => setState(() => _categoryId = v ?? ''),
        ),
        DateTimeFields(
          label: loc.adminNoticesFormPublishAt,
          hint: loc.adminNoticesFormPublishAtHint,
          date: _publishDate,
          time: _publishTime,
          onDateChanged: (v) => setState(() => _publishDate = v),
          onTimeChanged: (v) => setState(() => _publishTime = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _published,
          title: Text(loc.adminNoticesFormPublished),
          onChanged: (v) => setState(() => _published = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _membersOnly,
          title: Text(loc.adminNoticesFormMembersOnly),
          onChanged: (v) => setState(() => _membersOnly = v),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final publishAt =
        _publishDate.isEmpty ? null : isoFromParts(_publishDate, _publishTime);
    final ok = await dispatchForBool(
      widget.bloc,
      (c) => NoticeSaveRequested(
        completer: c,
        editingId: widget.editing?.id,
        payload: NoticeInput(
          title: _title.text.trim(),
          body: _body.text.trim(),
          categoryId: _categoryId.isEmpty ? null : _categoryId,
          isPublished: _published,
          isMembersOnly: _membersOnly,
          publishAt: publishAt,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }
}
