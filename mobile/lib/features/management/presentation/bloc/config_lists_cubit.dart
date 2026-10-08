import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

const configCategories = [
  'property_type',
  'document_type',
  'notice_category',
  'event_category',
  'finance_income_category',
  'finance_expense_category',
  'payment_account',
];

class ConfigListsState extends Equatable {
  const ConfigListsState({
    this.selectedCategory = 'property_type',
    this.items = const [],
    this.loading = false,
    this.error,
    this.busyId,
    this.editingId,
    this.saveError,
  });

  final String selectedCategory;
  final List<ConfigListItem> items;
  final bool loading;
  final Object? error;

  /// Item being toggled/saved/edited.
  final String? busyId;
  final String? editingId;
  final Object? saveError;

  ConfigListsState copyWith({
    String? selectedCategory,
    List<ConfigListItem>? items,
    bool? loading,
    Object? Function() error = _same,
    String? Function() busyId = _same,
    String? Function() editingId = _same,
    Object? Function() saveError = _same,
  }) =>
      ConfigListsState(
        selectedCategory: selectedCategory ?? this.selectedCategory,
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error == _same ? this.error : error(),
        busyId: busyId == _same ? this.busyId : busyId(),
        editingId: editingId == _same ? this.editingId : editingId(),
        saveError: saveError == _same ? this.saveError : saveError(),
      );

  static T _same<T>() => throw UnsupportedError('sentinel');

  @override
  List<Object?> get props =>
      [selectedCategory, items, loading, error, busyId, editingId, saveError];
}

class ConfigListsCubit extends Cubit<ConfigListsState> {
  ConfigListsCubit({required AdminRepository repository})
      : _repository = repository,
        super(const ConfigListsState());

  final AdminRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: () => null));
    try {
      final items =
          await _repository.listConfigListItems(state.selectedCategory);
      emit(state.copyWith(items: items, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: () => e));
    }
  }

  void selectCategory(String category) {
    emit(ConfigListsState(selectedCategory: category));
    load();
  }

  /// Adds a new item; label falls back to the value (Angular parity).
  Future<void> addItem(String value, String label) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    emit(state.copyWith(saveError: () => null));
    try {
      await _repository.createConfigListItem(
        category: state.selectedCategory,
        value: trimmed,
        label: label.trim().isEmpty ? trimmed : label.trim(),
        sortOrder: state.items.length,
      );
      await load();
    } catch (e) {
      emit(state.copyWith(saveError: () => e));
    }
  }

  Future<void> toggleActive(ConfigListItem item) async {
    emit(state.copyWith(busyId: () => item.id, error: () => null));
    try {
      final updated = await _repository.updateConfigListItem(item.id,
          isActive: !item.isActive);
      emit(state.copyWith(
        busyId: () => null,
        items: _replace(updated),
      ));
    } catch (e) {
      emit(state.copyWith(busyId: () => null, error: () => e));
    }
  }

  void startEdit(ConfigListItem item) {
    emit(state.copyWith(editingId: () => item.id));
  }

  void cancelEdit() {
    emit(state.copyWith(editingId: () => null));
  }

  Future<void> saveLabel(ConfigListItem item, String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty || trimmed == item.label) {
      cancelEdit();
      return;
    }
    emit(state.copyWith(busyId: () => item.id, error: () => null));
    try {
      final updated =
          await _repository.updateConfigListItem(item.id, label: trimmed);
      emit(state.copyWith(
          busyId: () => null, editingId: () => null, items: _replace(updated)));
    } catch (e) {
      emit(state.copyWith(busyId: () => null, error: () => e));
    }
  }

  /// Swaps sort_order with the neighbor, mirroring the Angular move flow.
  Future<void> moveItem(int index, int direction) async {
    final target = index + direction;
    if (target < 0 || target >= state.items.length) return;
    final current = state.items[index];
    final neighbor = state.items[target];
    emit(state.copyWith(busyId: () => current.id, error: () => null));
    try {
      await _repository.updateConfigListItem(current.id,
          sortOrder: neighbor.sortOrder);
      await _repository.updateConfigListItem(neighbor.id,
          sortOrder: current.sortOrder);
      emit(state.copyWith(
        busyId: () => null,
        items: List<ConfigListItem>.from(state.items)
          ..[index] = neighbor
          ..[target] = current,
      ));
    } catch (e) {
      emit(state.copyWith(busyId: () => null, error: () => e));
      await load(); // resync server-side sort order
    }
  }

  List<ConfigListItem> _replace(ConfigListItem updated) => [
        for (final i in state.items)
          if (i.id == updated.id) updated else i,
      ];
}
