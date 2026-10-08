import 'package:equatable/equatable.dart';

import '../../domain/admin_entities.dart';

/// Shared list state shape for notices/events management.
class ContentListState<T> extends Equatable {
  const ContentListState({
    this.items = const [],
    this.categories = const [],
    this.loading = true,
    this.error,
    this.publishedFilter,
    this.categoryFilter,
    this.busyId,
    this.saveError,
  });

  final List<T> items;
  final List<ConfigListItem> categories;
  final bool loading;
  final Object? error;

  /// null = all, true = published only, false = draft only.
  final bool? publishedFilter;
  final String? categoryFilter;
  final String? busyId;
  final Object? saveError;

  ContentListState<T> copyWith({
    List<T>? items,
    List<ConfigListItem>? categories,
    bool? loading,
    Object? Function()? error,
    bool? Function()? publishedFilter,
    String? Function()? categoryFilter,
    String? Function()? busyId,
    Object? Function()? saveError,
  }) =>
      ContentListState<T>(
        items: items ?? this.items,
        categories: categories ?? this.categories,
        loading: loading ?? this.loading,
        error: error == null ? this.error : error(),
        publishedFilter:
            publishedFilter == null ? this.publishedFilter : publishedFilter(),
        categoryFilter:
            categoryFilter == null ? this.categoryFilter : categoryFilter(),
        busyId: busyId == null ? this.busyId : busyId(),
        saveError: saveError == null ? this.saveError : saveError(),
      );

  @override
  List<Object?> get props => [
        items,
        categories,
        loading,
        error,
        publishedFilter,
        categoryFilter,
        busyId,
        saveError,
      ];
}

final class ContentListData<T> extends ContentListState<T> {
  const ContentListData({
    super.items,
    super.categories,
    super.loading,
    super.error,
    super.publishedFilter,
    super.categoryFilter,
    super.busyId,
    super.saveError,
  });
}
