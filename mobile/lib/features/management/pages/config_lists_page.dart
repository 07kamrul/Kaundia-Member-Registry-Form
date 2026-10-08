import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/admin_repository.dart';
import '../domain/admin_entities.dart';
import '../presentation/bloc/bloc_actions.dart';
import '../presentation/bloc/config_lists_bloc.dart';
import '../presentation/widgets/config_lists_widgets.dart';
import '../presentation/widgets/management_widgets.dart';

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
  /// Content width from which the add form sits beside the item list.
  static const double _sidePaneMinWidth = 900;
  static const double _sidePaneWidth = 320;

  final _valueController = TextEditingController();
  final _labelController = TextEditingController();
  final _editController = TextEditingController();
  bool _adding = false;

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
        ..add(const ConfigListsLoadRequested()),
      child: BlocConsumer<ConfigListsBloc, ConfigListsState>(
        listener: (context, state) {
          // Load failures on an empty list render inline instead.
          if (state.saveError != null ||
              (state.error != null && state.items.isNotEmpty)) {
            showAppToast(context, loc.adminConfigListsErrorsSaveFailed,
                error: true);
          }
        },
        builder: (context, state) {
          final bloc = context.read<ConfigListsBloc>();
          return PageBody(
            onRefresh: () => reloadAndWait(
                bloc, const ConfigListsLoadRequested(), (s) => s.loading),
            children: [
              PageHeader(
                icon: Icons.tune,
                title: loc.adminConfigListsTitle,
                subtitle: loc.adminConfigListsSubtitle,
              ),
              ManagementFilterChips<String>(
                selected: state.selectedCategory,
                options: [
                  for (final c in configCategories) (c, _categoryLabel(loc, c)),
                ],
                onSelected: (c) => bloc.add(ConfigListsCategorySelected(c)),
              ),
              const SizedBox(height: 8),
              _body(context, loc, bloc, state, canManage),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations loc,
      ConfigListsBloc bloc, ConfigListsState state, bool canManage) {
    final items = _items(loc, bloc, state, canManage);
    if (!canManage) return Column(children: items);
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < _sidePaneMinWidth) {
          return Column(children: [_addForm(context, loc, bloc), ...items]);
        }
        return Padding(
          padding: EdgeInsets.only(left: context.pageGutter),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _sidePaneWidth,
                child: _addForm(context, loc, bloc, margin: EdgeInsets.zero),
              ),
              Expanded(child: Column(children: items)),
            ],
          ),
        );
      },
    );
  }

  Widget _addForm(BuildContext context, AppLocalizations loc,
      ConfigListsBloc bloc,
      {EdgeInsetsGeometry? margin}) {
    return AppCard(
      title: loc.adminConfigListsAddItem,
      margin: margin,
      trailing: Icon(Icons.add_circle_outline,
          color: Theme.of(context).colorScheme.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _valueController,
            textInputAction: TextInputAction.next,
            decoration:
                InputDecoration(labelText: loc.adminConfigListsFormValue),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _labelController,
            textInputAction: TextInputAction.done,
            decoration:
                InputDecoration(labelText: loc.adminConfigListsFormLabel),
            onFieldSubmitted: (_) => _add(bloc),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: loc.adminConfigListsFormSubmit,
            icon: Icons.add,
            expanded: true,
            loading: _adding,
            onPressed: () => _add(bloc),
          ),
        ],
      ),
    );
  }

  Future<void> _add(ConfigListsBloc bloc) async {
    if (_adding) return;
    setState(() => _adding = true);
    final ok = await dispatchForBool(
      bloc,
      (c) => ConfigListItemAddRequested(
        _valueController.text,
        _labelController.text,
        c,
      ),
    );
    if (!mounted) return;
    setState(() => _adding = false);
    if (ok) {
      _valueController.clear();
      _labelController.clear();
    }
  }

  List<Widget> _items(AppLocalizations loc, ConfigListsBloc bloc,
      ConfigListsState state, bool canManage) {
    if (state.loading) return const [SkeletonLoader(lines: 4, height: 96)];
    if (state.items.isEmpty && state.error != null) {
      return [
        InlineError(
          message: loc.adminConfigListsErrorsLoadFailed,
          onRetry: () => bloc.add(const ConfigListsLoadRequested()),
        ),
      ];
    }
    if (state.items.isEmpty) {
      return [
        EmptyState(
            message: loc.adminConfigListsNoItems, icon: Icons.list_alt_outlined),
      ];
    }
    return [
      ManagementRecordGrid(
        minItemWidth: 300,
        children: [
          for (var i = 0; i < state.items.length; i++)
            _itemCard(bloc, state, state.items[i], i, canManage),
        ],
      ),
    ];
  }

  Widget _itemCard(ConfigListsBloc bloc, ConfigListsState state,
      ConfigListItem item, int index, bool canManage) {
    final busy = state.busyId == item.id;
    final canMove = canManage && !busy;
    return ConfigListItemCard(
      item: item,
      canManage: canManage,
      busy: busy,
      editing: state.editingId == item.id,
      editController: _editController,
      onEditStart: () {
        _editController.text = item.label;
        bloc.add(ConfigListItemEditStarted(item));
      },
      onEditSave: (v) => bloc.add(ConfigListItemLabelSaveRequested(item, v)),
      onEditCancel: () => bloc.add(const ConfigListItemEditCancelled()),
      onToggle: () => bloc.add(ConfigListItemToggleActiveRequested(item)),
      onMoveUp: canMove && index > 0
          ? () => bloc.add(ConfigListItemMoveRequested(index, -1))
          : null,
      onMoveDown: canMove && index < state.items.length - 1
          ? () => bloc.add(ConfigListItemMoveRequested(index, 1))
          : null,
    );
  }
}
