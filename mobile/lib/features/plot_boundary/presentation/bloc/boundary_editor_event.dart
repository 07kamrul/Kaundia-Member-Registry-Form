part of 'boundary_editor_bloc.dart';

sealed class BoundaryEditorEvent extends Equatable {
  const BoundaryEditorEvent();
  @override
  List<Object?> get props => const [];
}

/// Loads the property picker inputs; optionally starts editing a saved
/// boundary (its vertices are preloaded).
final class EditorStarted extends BoundaryEditorEvent {
  const EditorStarted({this.editing});
  final PlotBoundary? editing;
  @override
  List<Object?> get props => [editing];
}

/// Preloads the vertices of an existing boundary for editing.
final class EditorExistingLoaded extends BoundaryEditorEvent {
  const EditorExistingLoaded(this.boundary);
  final PlotBoundary boundary;
  @override
  List<Object?> get props => [boundary];
}

/// Tap on the map adds a vertex at [point].
final class EditorVertexAdded extends BoundaryEditorEvent {
  const EditorVertexAdded(this.point);
  final LatLng point;
  @override
  List<Object?> get props => [point];
}

/// Marks the start of a vertex drag; pushes a single undo entry for the
/// whole drag (move events themselves do not grow the undo stack).
final class EditorVertexMoveStarted extends BoundaryEditorEvent {
  const EditorVertexMoveStarted(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

final class EditorVertexMoved extends BoundaryEditorEvent {
  const EditorVertexMoved(this.index, this.point);
  final int index;
  final LatLng point;
  @override
  List<Object?> get props => [index, point];
}

final class EditorVertexRemoved extends BoundaryEditorEvent {
  const EditorVertexRemoved(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

final class EditorUndoPressed extends BoundaryEditorEvent {
  const EditorUndoPressed();
}

final class EditorCleared extends BoundaryEditorEvent {
  const EditorCleared();
}

final class EditorPropertyChanged extends BoundaryEditorEvent {
  const EditorPropertyChanged(this.propertyId);
  final String propertyId;
  @override
  List<Object?> get props => [propertyId];
}

/// POST when drawing new, PUT when editing; result is pending_review.
final class EditorSaveRequested extends BoundaryEditorEvent {
  const EditorSaveRequested();
}
