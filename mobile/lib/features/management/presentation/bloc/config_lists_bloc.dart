import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/admin_repository.dart';
import '../../domain/admin_entities.dart';

part 'config_lists_event.dart';
part 'config_lists_state.dart';

const configCategories = [
  'property_type',
  'document_type',
  'notice_category',
  'event_category',
  'finance_income_category',
  'finance_expense_category',
  'payment_account',
];

class ConfigListsBloc extends Bloc<ConfigListsEvent, ConfigListsState> {
  ConfigListsBloc({required AdminRepository repository})
      : _repository = repository,
        super(const ConfigListsData()) {
    on<ConfigListsLoadRequested>((event, emit) => _load(emit));
    on<ConfigListsCategorySelected>((event, emit) async {
      emit(ConfigListsData(selectedCategory: event.category));
      await _load(emit);
    });
    on<ConfigListItemAddRequested>((event, emit) async {
      final trimmed = event.value.trim();
      if (trimmed.isEmpty) {
        event.completer?.complete(false);
        return;
      }
      emit(_d.copyWith(saveError: () => null));
      try {
        await _repository.createConfigListItem(
          category: state.selectedCategory,
          value: trimmed,
          label: event.label.trim().isEmpty ? trimmed : event.label.trim(),
          sortOrder: state.items.length,
        );
        event.completer?.complete(true);
        await _load(emit);
      } catch (e) {
        event.completer?.complete(false);
        emit(_d.copyWith(saveError: () => e));
      }
    });
    on<ConfigListItemToggleActiveRequested>(
        (event, emit) => _toggle(event.item, emit));
    on<ConfigListItemEditStarted>(
        (event, emit) => emit(_d.copyWith(editingId: () => event.item.id)));
    on<ConfigListItemEditCancelled>(
        (event, emit) => emit(_d.copyWith(editingId: () => null)));
    on<ConfigListItemLabelSaveRequested>(
        (event, emit) => _saveLabel(event.item, event.label, emit));
    on<ConfigListItemMoveRequested>(
        (event, emit) => _move(event.index, event.direction, emit));
  }

  final AdminRepository _repository;

  /// Current state; copyWith returns the base state type, so never
  /// downcast here (that would silently reset to defaults).
  ConfigListsState get _d => state;

  Future<void> _load(Emitter<ConfigListsState> emit) async {
    emit(_d.copyWith(loading: true, error: () => null));
    try {
      final items =
          await _repository.listConfigListItems(state.selectedCategory);
      emit(_d.copyWith(items: items, loading: false));
    } catch (e) {
      emit(_d.copyWith(loading: false, error: () => e));
    }
  }

  Future<void> _toggle(
      ConfigListItem item, Emitter<ConfigListsState> emit) async {
    emit(_d.copyWith(busyId: () => item.id, error: () => null));
    try {
      final updated = await _repository.updateConfigListItem(item.id,
          isActive: !item.isActive);
      emit(_d.copyWith(busyId: () => null, items: _replace(updated)));
    } catch (e) {
      emit(_d.copyWith(busyId: () => null, error: () => e));
    }
  }

  Future<void> _saveLabel(
      ConfigListItem item, String label, Emitter<ConfigListsState> emit) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty || trimmed == item.label) {
      emit(_d.copyWith(editingId: () => null));
      return;
    }
    emit(_d.copyWith(busyId: () => item.id, error: () => null));
    try {
      final updated =
          await _repository.updateConfigListItem(item.id, label: trimmed);
      emit(_d.copyWith(
          busyId: () => null, editingId: () => null, items: _replace(updated)));
    } catch (e) {
      emit(_d.copyWith(busyId: () => null, error: () => e));
    }
  }

  Future<void> _move(
      int index, int direction, Emitter<ConfigListsState> emit) async {
    final target = index + direction;
    if (target < 0 || target >= state.items.length) return;
    final current = state.items[index];
    final neighbor = state.items[target];
    emit(_d.copyWith(busyId: () => current.id, error: () => null));
    try {
      await _repository.updateConfigListItem(current.id,
          sortOrder: neighbor.sortOrder);
      await _repository.updateConfigListItem(neighbor.id,
          sortOrder: current.sortOrder);
      emit(_d.copyWith(
        busyId: () => null,
        items: List<ConfigListItem>.from(state.items)
          ..[index] = neighbor
          ..[target] = current,
      ));
    } catch (e) {
      emit(_d.copyWith(busyId: () => null, error: () => e));
      await _load(emit); // resync server-side sort order
    }
  }

  List<ConfigListItem> _replace(ConfigListItem updated) => [
        for (final i in state.items)
          if (i.id == updated.id) updated else i,
      ];
}
