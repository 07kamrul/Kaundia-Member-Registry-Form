import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/content_cubit.dart';
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

  const NoticesManagementPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<NoticesManagementPage> createState() => _NoticesManagementPageState();
}

class _NoticesManagementPageState extends State<NoticesManagementPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => NoticesCubit(repository: AdminRepository(apiClient: sl<ApiClient>()))..init(),
      child: BlocConsumer<NoticesCubit, ContentListState<Notice>>(
        listener: (context, state) {
          if (state.saveError != null) {
            showAppToast(context, loc.adminNoticesErrorsSaveFailed, error: true);
          }
          if (state.error != null) {
            showAppToast(context, loc.adminNoticesErrorsLoadFailed, error: true);
          }
        },
        builder: (context, state) {
          final cubit = context.read<NoticesCubit>();
          return ListView(
            children: [
              PageHeader(title: loc.adminNoticesTitle, subtitle: loc.adminNoticesSubtitle),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AppTabs(
                        labels: [
                          loc.adminNoticesFiltersAll,
                          loc.adminNoticesFiltersPublished,
                          loc.adminNoticesFiltersDraft,
                        ],
                        selectedIndex: state.publishedFilter == null
                            ? 0
                            : state.publishedFilter == true
                                ? 1
                                : 2,
                        onChanged: cubit.setStatusFilter,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: state.categoryFilter,
                        decoration: InputDecoration(
                          labelText: loc.adminNoticesFiltersCategory,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(loc.adminNoticesFiltersAllCategories),
                          ),
                          for (final c in state.categories)
                            DropdownMenuItem<String?>(value: c.id, child: Text(c.label)),
                        ],
                        onChanged: cubit.setCategoryFilter,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AppButton(
                  label: loc.adminNoticesCreate,
                  icon: Icons.add,
                  onPressed: () => _openForm(context, loc, cubit),
                ),
              ),
              if (state.loading)
                const SkeletonLoader(lines: 4)
              else if (state.items.isEmpty)
                EmptyState(message: loc.adminNoticesNoItems)
              else
                AppDataTableCards<Notice>(
                  items: state.items,
                  rowBuilder: (context, n) => _row(context, loc, cubit, n),
                ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(AppLocalizations loc, Notice n) {
    if (!n.isPublished) return loc.adminNoticesStatusDraft;
    final publishAt = DateTime.tryParse(n.publishAt ?? '');
    if (publishAt != null && publishAt.isAfter(DateTime.now())) {
      return loc.adminNoticesStatusScheduled;
    }
    return loc.adminNoticesStatusPublished;
  }

  Widget _row(BuildContext context, AppLocalizations loc, NoticesCubit cubit, Notice n) {
    final category = state_categoryLabel(context, n.categoryId);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    n.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                StatusBadge(
                  kind: n.isPublished ? StatusKind.approved : StatusKind.neutral,
                  label: _statusLabel(loc, n),
                ),
              ],
            ),
            const SizedBox(height: 6),
            InfoRow(label: loc.adminNoticesTableCategory, value: category),
            if (n.publishAt != null)
              InfoRow(
                label: loc.adminNoticesTablePublishAt,
                value: datetimeParts(n.publishAt).$1.isNotEmpty
                    ? '${datetimeParts(n.publishAt).$1} ${datetimeParts(n.publishAt).$2}'
                    : '—',
              ),
            if (n.isMembersOnly)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: StatusBadge(
                  kind: StatusKind.pending,
                  label: loc.adminNoticesMembersOnlyBadge,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: n.isPublished ? loc.adminNoticesUnpublish : loc.adminNoticesPublish,
                  variant: AppButtonVariant.ghost,
                  onPressed:
                      state_busy(context, n.id) ? null : () => cubit.togglePublished(n),
                ),
                AppButton(
                  label: loc.commonEdit,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => _openForm(context, loc, cubit, editing: n),
                ),
                AppButton(
                  label: loc.commonDelete,
                  variant: AppButtonVariant.ghost,
                  onPressed: () async {
                    final confirmed = await AppDialog.confirm(
                      context,
                      title: loc.adminNoticesDeleteModalTitle,
                      message: loc.adminNoticesDeleteModalMessageSuffix,
                      destructive: true,
                    );
                    if (confirmed && context.mounted) await cubit.delete(n);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool state_busy(BuildContext context, String id) =>
      context.read<NoticesCubit>().state.busyId == id;

  String state_categoryLabel(BuildContext context, String? categoryId) {
    if (categoryId == null) return '—';
    final categories = context.read<NoticesCubit>().state.categories;
    for (final c in categories) {
      if (c.id == categoryId) return c.label;
    }
    return '—';
  }

  Future<void> _openForm(BuildContext context, AppLocalizations loc, NoticesCubit cubit,
      {Notice? editing}) async {
    final titleController = TextEditingController(text: editing?.title ?? '');
    final bodyController = TextEditingController(text: editing?.body ?? '');
    var categoryId = editing?.categoryId ?? '';
    final publishParts = datetimeParts(editing?.publishAt);
    var publishDate = publishParts.$1;
    var publishTime = publishParts.$2;
    var published = editing?.isPublished ?? false;
    var membersOnly = editing?.isMembersOnly ?? false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (sheetContext, setSheetState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  editing == null
                      ? loc.adminNoticesFormCreateTitle
                      : loc.adminNoticesFormEditTitle,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: loc.adminNoticesFormTitle,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bodyController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: loc.adminNoticesFormBody,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: categoryId.isEmpty ? null : categoryId,
                  decoration: InputDecoration(
                    labelText: loc.adminNoticesFormCategory,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(loc.adminNoticesFormNoCategory),
                    ),
                    for (final c in cubit.state.categories)
                      DropdownMenuItem<String>(value: c.id, child: Text(c.label)),
                  ],
                  onChanged: (v) => setSheetState(() => categoryId = v ?? ''),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DateField(
                        label: loc.adminNoticesFormPublishAt,
                        hint: loc.adminNoticesFormPublishAtHint,
                        value: publishDate,
                        onChanged: (v) => setSheetState(() => publishDate = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: publishTime,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'HH:mm',
                          border: const OutlineInputBorder(),
                        ),
                        onTap: () async {
                          final initial = _parseTime(publishTime) ?? TimeOfDay.now();
                          final picked = await showTimePicker(
                            context: sheetContext,
                            initialTime: initial,
                          );
                          if (picked != null) {
                            setSheetState(() => publishTime = picked.format(sheetContext));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  value: published,
                  title: Text(loc.adminNoticesFormPublished),
                  onChanged: (v) => setSheetState(() => published = v ?? false),
                ),
                CheckboxListTile(
                  value: membersOnly,
                  title: Text(loc.adminNoticesFormMembersOnly),
                  onChanged: (v) => setSheetState(() => membersOnly = v ?? false),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: editing == null
                        ? loc.adminNoticesFormCreate
                        : loc.commonSave,
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty ||
                          bodyController.text.trim().isEmpty) {
                        return;
                      }
                      final publishAt = publishDate.isEmpty
                          ? null
                          : isoFromParts(publishDate, publishTime);
                      final ok = await cubit.save(
                        editingId: editing?.id,
                        payload: NoticeInput(
                          title: titleController.text.trim(),
                          body: bodyController.text.trim(),
                          categoryId: categoryId.isEmpty ? null : categoryId,
                          isPublished: published,
                          isMembersOnly: membersOnly,
                          publishAt: publishAt,
                        ),
                      );
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop(ok);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      showAppToast(context, loc.commonSave);
    }
  }
}

TimeOfDay? _parseTime(String text) {
  final parts = text.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h, minute: m);
}
