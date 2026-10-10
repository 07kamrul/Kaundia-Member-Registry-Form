part of 'boundary_editor_bloc.dart';

class BoundaryEditorState extends Equatable {
  const BoundaryEditorState({
    this.status = EditorStatus.loading,
    this.vertices = const [],
    this.undoStack = const [],
    this.properties = const [],
    this.availableProperties = const [],
    this.boundaries = const [],
    this.selectedPropertyId,
    this.editingId,
    this.saved,
    this.failureKind,
    this.society,
    this.editingHasPending = false,
  });

  final EditorStatus status;

  /// Society extent used by the live validation; null disables that check.
  final SocietyBbox? society;

  /// The boundary being edited has a submission awaiting review, so saving
  /// replaces it (the page asks for confirmation first).
  final bool editingHasPending;

  /// Drawn vertices (open ring; closed on save by the mapper).
  final List<LatLng> vertices;

  /// Previous vertex lists for undo.
  final List<List<LatLng>> undoStack;

  /// All own plots (picker shows the full list when nothing is filtered).
  final List<OwnProperty> properties;

  /// Own plots without a boundary yet — the preferred save targets.
  final List<OwnProperty> availableProperties;
  final List<PlotBoundary> boundaries;
  final String? selectedPropertyId;
  final String? editingId;

  /// The boundary returned by a successful save (status pending_review).
  final PlotBoundary? saved;
  final PlotBoundaryFailureKind? failureKind;

  OwnProperty? get selectedProperty {
    final id = selectedPropertyId;
    if (id == null) return null;
    for (final p in properties) {
      if (p.propertyId == id) return p;
    }
    return null;
  }

  /// Live client-side validation + area estimate for the current vertices.
  BoundaryValidation get validation => validate(
        vertices,
        bbox: society,
        declaredShotangsho:
            parseDeclaredShotangsho(selectedProperty?.landQuantity),
      );

  bool get canUndo => undoStack.isNotEmpty;

  bool get canSave =>
      selectedPropertyId != null &&
      validation.canSave &&
      status != EditorStatus.saving;

  BoundaryEditorState copyWith({
    EditorStatus? status,
    List<LatLng>? vertices,
    bool clearVertices = false,
    List<List<LatLng>>? undoStack,
    List<OwnProperty>? properties,
    List<OwnProperty>? availableProperties,
    List<PlotBoundary>? boundaries,
    String? selectedPropertyId,
    String? editingId,
    PlotBoundary? saved,
    PlotBoundaryFailureKind? failureKind,
    bool clearFailure = false,
    bool? editingHasPending,
  }) {
    return BoundaryEditorState(
      status: status ?? this.status,
      vertices: clearVertices ? const [] : (vertices ?? this.vertices),
      undoStack: undoStack ?? this.undoStack,
      properties: properties ?? this.properties,
      availableProperties: availableProperties ?? this.availableProperties,
      boundaries: boundaries ?? this.boundaries,
      selectedPropertyId: selectedPropertyId ?? this.selectedPropertyId,
      editingId: editingId ?? this.editingId,
      saved: saved ?? this.saved,
      failureKind: clearFailure ? null : (failureKind ?? this.failureKind),
      society: society,
      editingHasPending: editingHasPending ?? this.editingHasPending,
    );
  }

  @override
  List<Object?> get props => [
        status,
        vertices,
        undoStack,
        properties,
        availableProperties,
        boundaries,
        selectedPropertyId,
        editingId,
        saved,
        failureKind,
        society,
        editingHasPending,
      ];
}
