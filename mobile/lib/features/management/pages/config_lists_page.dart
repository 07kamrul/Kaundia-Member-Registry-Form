import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/config_lists_bloc.dart';

/// Config list management (Angular config-lists): category tabs, add item,
/// activate/deactivate toggle, inline label edit, reorder.
class ConfigListsPage extends StatefulWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const ConfigListsPage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  State<ConfigListsPage> createState() => _ConfigListsPageState();
}

class _ConfigListsPageState extends State<ConfigListsPage> {
  final _valueController = TextEditingController();
  final _labelController = TextEditingController();
  final _editController = TextEditingController();

  String _categoryLabel(AppLocalizations loc, String category) =>
      switch (category) {
        'property_type' => loc.adminConfigListsCategoriesPropertyType,
        'document_type' => loc.adminConfigListsCategoriesDocumentType,
        'notice_category' => loc.adminConfigListsCategoriesNoticeCategory,
        'event_category' => loc.adminConfigListsCategoriesEventCategory,
        'finance_income_category' =>
          loc.adminConfigListsCategoriesFinanceIncomeCategory,
        'finance_expense_category' =>
          loc.adminConfigListsCategoriesFinanceExpenseCategory,
        'payment_account' => loc.adminConfigListsCategoriesPaymentAccount,
        _ => category,
      };

  @override
  void dispose() {
    _valueController.dispose();
    _labelController.dispose();
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final canManage =
        sl<SessionManager>().session?.can('manage_system_config') ?? false;
    return BlocProvider(
      create: (_) => ConfigListsBloc(
          repository: AdminRepository(apiClient: sl<ApiClient>()))
        ..load(),
      child: BlocConsumer<ConfigListsBloc, ConfigListsState>(
        listener: (context, state) {
          if (state.saveError != null) {
            showAppToast(context, loc.adminConfigListsErrorsSaveFailed,
                error: true);
          } else if (state.error != null) {
            showAppToast(context, loc.adminConfigListsErrorsSaveFailed,
                error: true);
          }
        },
        builder: (context, state) {
          final bloc = context.read<ConfigListsBloc>();
          return ListView(
            children: [
              PageHeader(
                  title: loc.adminConfigListsTitle,
                  subtitle: loc.adminConfigListsSubtitle),
              // Category tabs.
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: configCategories.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_categoryLabel(loc, configCategories[index])),
                      selected:
                          state.selectedCategory == configCategories[index],
                      onSelected: (_) =>
                          bloc.add(ConfigListsCategorySelected(configCategories[index])),
                    ),
                  ),
                ),
              ),
              // Add item.
              AppCard(
                title: loc.adminConfigListsAddItem,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _valueController,
                      enabled: canManage,
                      decoration: InputDecoration(
                        labelText: loc.adminConfigListsFormValue,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _labelController,
                      enabled: canManage,
                      decoration: InputDecoration(
                        labelText: loc.adminConfigListsFormLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: loc.adminConfigListsFormSubmit,
                        onPressed: canManage
                            ? () async {
                                bloc.add(ConfigListItemAddRequested(_valueController.text, _labelController.text));
                                _valueController.clear();
                                _labelController.clear();
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.loading)
                const SkeletonLoader(lines: 4)
              else if (state.items.isEmpty)
                EmptyState(message: loc.adminConfigListsNoItems)
              else
                AppDataTableCards<ConfigListItem>(
                  items: state.items,
                  rowBuilder: (context, item) =>
                      _row(context, loc, bloc, state, item, canManage),
                ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _row(
      BuildContext context,
      AppLocalizations loc,
      ConfigListsBloc bloc,
      ConfigListsState state,
      ConfigListItem item,
      bool canManage) {
    final busy = state.busyId == item.id;
    final editing = state.editingId == item.id;
    final index = state.items.indexOf(item);
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
                    item.value,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                StatusBadge(
                  kind:
                      item.isActive ? StatusKind.approved : StatusKind.neutral,
                  label: item.isActive
                      ? loc.adminConfigListsActive
                      : loc.adminConfigListsInactive,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Inline label edit.
            if (editing)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _editController,
                      autofocus: true,
                      enabled: !busy,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                      onFieldSubmitted: (v) => bloc.add(ConfigListItemLabelSaveRequested(item, v)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: busy
                        ? null
                        : () => bloc.add(ConfigListItemLabelSaveRequested(item, _editController.text)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: busy ? null : () => bloc.add(const ConfigListItemEditCancelled()),
                  ),
                ],
              )
            else
              InkWell(
                onTap: canManage
                    ? () {
                        _editController.text = item.label;
                        bloc.add(ConfigListItemEditStarted(item));
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.label)),
                      if (canManage) const Icon(Icons.edit_outlined, size: 16),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: loc.adminConfigListsActionsMoveUp,
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: canManage && !busy && index > 0
                      ? () => bloc.add(ConfigListItemMoveRequested(index, -1))
                      : null,
                ),
                IconButton(
                  tooltip: loc.adminConfigListsActionsMoveDown,
                  icon: const Icon(Icons.arrow_downward),
                  onPressed:
                      canManage && !busy && index < state.items.length - 1
                          ? () => bloc.add(ConfigListItemMoveRequested(index, 1))
                          : null,
                ),
                if (canManage)
                  Switch(
                    value: item.isActive,
                    onChanged: busy ? null : (_) => bloc.add(ConfigListItemToggleActiveRequested(item)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
