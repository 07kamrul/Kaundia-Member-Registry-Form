part of 'config_lists_bloc.dart';

sealed class ConfigListsEvent extends Equatable {
  const ConfigListsEvent();

  @override
  List<Object?> get props => const [];
}

final class ConfigListsLoadRequested extends ConfigListsEvent {
  const ConfigListsLoadRequested();
}

final class ConfigListsCategorySelected extends ConfigListsEvent {
  const ConfigListsCategorySelected(this.category);

  final String category;

  @override
  List<Object?> get props => [category];
}

final class ConfigListItemAddRequested extends ConfigListsEvent {
  const ConfigListItemAddRequested(this.value, this.label, [this.completer]);

  final String value;
  final String label;

  /// Optional result channel: true when the item was added.
  final Completer<bool>? completer;

  @override
  List<Object?> get props => [value, label];
}

final class ConfigListItemToggleActiveRequested extends ConfigListsEvent {
  const ConfigListItemToggleActiveRequested(this.item);

  final ConfigListItem item;

  @override
  List<Object?> get props => [item];
}

final class ConfigListItemEditStarted extends ConfigListsEvent {
  const ConfigListItemEditStarted(this.item);

  final ConfigListItem item;

  @override
  List<Object?> get props => [item];
}

final class ConfigListItemEditCancelled extends ConfigListsEvent {
  const ConfigListItemEditCancelled();
}

final class ConfigListItemLabelSaveRequested extends ConfigListsEvent {
  const ConfigListItemLabelSaveRequested(this.item, this.label);

  final ConfigListItem item;
  final String label;

  @override
  List<Object?> get props => [item, label];
}

final class ConfigListItemMoveRequested extends ConfigListsEvent {
  const ConfigListItemMoveRequested(this.index, this.direction);

  final int index;
  final int direction;

  @override
  List<Object?> get props => [index, direction];
}
