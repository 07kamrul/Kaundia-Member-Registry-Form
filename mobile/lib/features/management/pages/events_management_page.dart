import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/content_cubit.dart';
import '../presentation/widgets/management_widgets.dart';
import 'notices_management_page.dart' show datetimeParts, isoFromParts;

/// Events management (Angular events): status/category filters, CRUD,
/// publish toggle, delete with confirm.
class EventsManagementPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const EventsManagementPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<EventsManagementPage> createState() => _EventsManagementPageState();
}

class _EventsManagementPageState extends State<EventsManagementPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => EventsCubit(repository: AdminRepository(apiClient: sl<ApiClient>()))..init(),
      child: BlocConsumer<EventsCubit, ContentListState<EventItem>>(
        listener: (context, state) {
          if (state.saveError != null) {
            showAppToast(context, loc.adminEventsErrorsSaveFailed, error: true);
          }
          if (state.error != null) {
            showAppToast(context, loc.adminEventsErrorsLoadFailed, error: true);
          }
        },
        builder: (context, state) {
          final cubit = context.read<EventsCubit>();
          return ListView(
            children: [
              PageHeader(title: loc.adminEventsTitle, subtitle: loc.adminEventsSubtitle),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppTabs(
                  labels: [
                    loc.adminEventsFiltersAll,
                    loc.adminEventsFiltersPublished,
                    loc.adminEventsFiltersDraft,
                  ],
                  selectedIndex: state.publishedFilter == null
                      ? 0
                      : state.publishedFilter == true
                          ? 1
                          : 2,
                  onChanged: cubit.setStatusFilter,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String?>(
                  initialValue: state.categoryFilter,
                  decoration: InputDecoration(
                    labelText: loc.adminEventsFiltersCategory,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(loc.adminEventsFiltersAllCategories),
                    ),
                    for (final c in state.categories)
                      DropdownMenuItem<String?>(value: c.id, child: Text(c.label)),
                  ],
                  onChanged: cubit.setCategoryFilter,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AppButton(
                  label: loc.adminEventsCreate,
                  icon: Icons.add,
                  onPressed: () => _openForm(context, loc, cubit),
                ),
              ),
              if (state.loading)
                const SkeletonLoader(lines: 4)
              else if (state.items.isEmpty)
                EmptyState(message: loc.adminEventsNoItems)
              else
                AppDataTableCards<EventItem>(
                  items: state.items,
                  rowBuilder: (context, e) => _row(context, loc, cubit, e),
                ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, AppLocalizations loc, EventsCubit cubit, EventItem e) {
    String categoryLabel(String? categoryId) {
      if (categoryId == null) return '—';
      for (final c in cubit.state.categories) {
        if (c.id == categoryId) return c.label;
      }
      return '—';
    }

    final startParts = datetimeParts(e.startAt);
    final endParts = datetimeParts(e.endAt);
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
                    e.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                StatusBadge(
                  kind: e.isPublished ? StatusKind.approved : StatusKind.neutral,
                  label: e.isPublished
                      ? loc.adminEventsStatusPublished
                      : loc.adminEventsStatusDraft,
                ),
              ],
            ),
            const SizedBox(height: 6),
            InfoRow(label: loc.adminEventsTableCategory, value: categoryLabel(e.categoryId)),
            InfoRow(
              label: loc.adminEventsTableWhen,
              value:
                  '${startParts.$1} ${startParts.$2}${endParts.$1.isEmpty ? '' : ' → ${endParts.$1} ${endParts.$2}'}',
            ),
            if (e.location != null && e.location!.isNotEmpty)
              InfoRow(label: loc.adminEventsTableLocation, value: e.location!),
            if (e.isMembersOnly)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: StatusBadge(
                  kind: StatusKind.pending,
                  label: loc.adminEventsMembersOnlyBadge,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: e.isPublished ? loc.adminEventsUnpublish : loc.adminEventsPublish,
                  variant: AppButtonVariant.ghost,
                  onPressed: cubit.state.busyId == e.id ? null : () => cubit.togglePublished(e),
                ),
                AppButton(
                  label: loc.commonEdit,
                  variant: AppButtonVariant.ghost,
                  onPressed: () => _openForm(context, loc, cubit, editing: e),
                ),
                AppButton(
                  label: loc.commonDelete,
                  variant: AppButtonVariant.ghost,
                  onPressed: () async {
                    final confirmed = await AppDialog.confirm(
                      context,
                      title: loc.adminEventsDeleteModalTitle,
                      message: loc.adminEventsDeleteModalMessageSuffix,
                      destructive: true,
                    );
                    if (confirmed && context.mounted) await cubit.delete(e);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, AppLocalizations loc, EventsCubit cubit,
      {EventItem? editing}) async {
    final titleController = TextEditingController(text: editing?.title ?? '');
    final descriptionController = TextEditingController(text: editing?.description ?? '');
    final locationController = TextEditingController(text: editing?.location ?? '');
    var categoryId = editing?.categoryId ?? '';
    final startParts = datetimeParts(editing?.startAt);
    var startDate = startParts.$1;
    var startTime = startParts.$2;
    final endParts = datetimeParts(editing?.endAt);
    var endDate = endParts.$1;
    var endTime = endParts.$2;
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
                      ? loc.adminEventsFormCreateTitle
                      : loc.adminEventsFormEditTitle,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: loc.adminEventsFormTitle,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: loc.adminEventsFormDescription,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: loc.adminEventsFormLocation,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: categoryId.isEmpty ? null : categoryId,
                  decoration: InputDecoration(
                    labelText: loc.adminEventsFormCategory,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(loc.adminEventsFormNoCategory),
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
                        label: loc.adminEventsFormStartAt,
                        value: startDate,
                        onChanged: (v) => setSheetState(() => startDate = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: startTime,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'HH:mm',
                          border: OutlineInputBorder(),
                        ),
                        onTap: () async {
                          final initial =
                              _parseTime(startTime) ?? TimeOfDay.now();
                          final picked = await showTimePicker(
                            context: sheetContext,
                            initialTime: initial,
                          );
                          if (picked != null) {
                            setSheetState(() => startTime = picked.format(sheetContext));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DateField(
                        label: loc.adminEventsFormEndAt,
                        value: endDate,
                        onChanged: (v) => setSheetState(() => endDate = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: endTime,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'HH:mm',
                          border: OutlineInputBorder(),
                        ),
                        onTap: () async {
                          final initial = _parseTime(endTime) ?? TimeOfDay.now();
                          final picked = await showTimePicker(
                            context: sheetContext,
                            initialTime: initial,
                          );
                          if (picked != null) {
                            setSheetState(() => endTime = picked.format(sheetContext));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  value: published,
                  title: Text(loc.adminEventsFormPublished),
                  onChanged: (v) => setSheetState(() => published = v ?? false),
                ),
                CheckboxListTile(
                  value: membersOnly,
                  title: Text(loc.adminEventsFormMembersOnly),
                  onChanged: (v) => setSheetState(() => membersOnly = v ?? false),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label:
                        editing == null ? loc.adminEventsFormCreate : loc.commonSave,
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty || startDate.isEmpty) return;
                      final startAt = isoFromParts(startDate, startTime);
                      final endAt = endDate.isEmpty ? null : isoFromParts(endDate, endTime);
                      final ok = await cubit.save(
                        editingId: editing?.id,
                        payload: EventInput(
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          location: locationController.text.trim().isEmpty
                              ? null
                              : locationController.text.trim(),
                          categoryId: categoryId.isEmpty ? null : categoryId,
                          startAt: startAt,
                          endAt: endAt,
                          isPublished: published,
                          isMembersOnly: membersOnly,
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
