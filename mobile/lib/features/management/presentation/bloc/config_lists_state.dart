part of 'config_lists_bloc.dart';

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

  /// Item being toggled/saved/moved.
  final String? busyId;
  final String? editingId;
  final Object? saveError;

  ConfigListsState copyWith({
    String? selectedCategory,
    List<ConfigListItem>? items,
    bool? loading,
    Object? Function()? error,
    String? Function()? busyId,
    String? Function()? editingId,
    Object? Function()? saveError,
  }) =>
      ConfigListsState(
        selectedCategory: selectedCategory ?? this.selectedCategory,
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
        busyId: busyId == null ? this.busyId : busyId(),
        editingId: editingId == null ? this.editingId : editingId(),
        saveError: saveError == null ? this.saveError : saveError(),
      );

  @override
  List<Object?> get props =>
      [selectedCategory, items, loading, error, busyId, editingId, saveError];
}

final class ConfigListsData extends ConfigListsState {
  const ConfigListsData({
    super.selectedCategory,
    super.items,
    super.loading,
    super.error,
    super.busyId,
    super.editingId,
    super.saveError,
  });
}
