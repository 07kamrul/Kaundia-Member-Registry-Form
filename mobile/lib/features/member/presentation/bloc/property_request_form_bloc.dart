import 'dart:io';

import 'package:dio/dio.dart' show DioMediaType;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/utils/file_utils.dart';
import '../../data/member_repository.dart';
import '../../domain/member_entities.dart';

/// Doc file row in the form (Angular NewDocRow / ExistingDocRow).
class FormDocRow extends Equatable {
  const FormDocRow({
    required this.docType,
    this.filePath,
    this.localPath,
    this.keep = true,
    this.error,
  });

  /// Existing doc (edit mode): kept by default via [keep].
  final String docType;
  final String? filePath;
  final String? localPath;
  final bool keep;
  final String? error;

  bool get isIncomplete => docType.isEmpty || (localPath == null && filePath == null);

  FormDocRow copyWith({
    String? docType,
    String? filePath,
    String? localPath,
    bool? keep,
    String? error,
    bool clearError = false,
  }) {
    return FormDocRow(
      docType: docType ?? this.docType,
      filePath: filePath ?? this.filePath,
      localPath: localPath ?? this.localPath,
      keep: keep ?? this.keep,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [docType, filePath, localPath, keep, error];
}

class FormCoOwnerRow extends Equatable {
  const FormCoOwnerRow({this.ownerName = '', this.ownerPhone = ''});

  final String ownerName;
  final String ownerPhone;

  FormCoOwnerRow copyWith({String? ownerName, String? ownerPhone}) =>
      FormCoOwnerRow(
        ownerName: ownerName ?? this.ownerName,
        ownerPhone: ownerPhone ?? this.ownerPhone,
      );

  @override
  List<Object?> get props => [ownerName, ownerPhone];
}

// Events --------------------------------------------------------------------

sealed class PropertyRequestFormEvent extends Equatable {
  const PropertyRequestFormEvent();

  @override
  List<Object?> get props => const [];
}

class PropertyRequestFormInitialized extends PropertyRequestFormEvent {
  const PropertyRequestFormInitialized({this.propertyId});

  final String? propertyId;
}

class PropertyRequestFormFieldChanged extends PropertyRequestFormEvent {
  const PropertyRequestFormFieldChanged({
    this.propertyType,
    this.propertyTypeOther,
    this.khatianNo,
    this.dagNoCs,
    this.dagNoRs,
    this.holdingNumber,
    this.landQuantity,
    this.myShareQuantity,
    this.ownership,
  });

  final List<String>? propertyType;
  final String? propertyTypeOther;
  final String? khatianNo;
  final String? dagNoCs;
  final String? dagNoRs;
  final String? holdingNumber;
  final String? landQuantity;
  final String? myShareQuantity;
  final String? ownership;

  @override
  List<Object?> get props => [
        propertyType, propertyTypeOther, khatianNo, dagNoCs, dagNoRs,
        holdingNumber, landQuantity, myShareQuantity, ownership,
      ];
}

class PropertyRequestFormCoOwnerAdded extends PropertyRequestFormEvent {
  const PropertyRequestFormCoOwnerAdded();
}

class PropertyRequestFormCoOwnerRemoved extends PropertyRequestFormEvent {
  const PropertyRequestFormCoOwnerRemoved(this.index);

  final int index;
}

class PropertyRequestFormCoOwnerChanged extends PropertyRequestFormEvent {
  const PropertyRequestFormCoOwnerChanged(this.index, this.row);

  final int index;
  final FormCoOwnerRow row;
}

class PropertyRequestFormDocAdded extends PropertyRequestFormEvent {
  const PropertyRequestFormDocAdded();
}

class PropertyRequestFormDocRemoved extends PropertyRequestFormEvent {
  const PropertyRequestFormDocRemoved(this.index);

  final int index;
}

class PropertyRequestFormDocChanged extends PropertyRequestFormEvent {
  const PropertyRequestFormDocChanged(this.index, this.row);

  final int index;
  final FormDocRow row;
}

class PropertyRequestFormExistingDocKeepChanged extends PropertyRequestFormEvent {
  const PropertyRequestFormExistingDocKeepChanged(this.index, {required this.keep});

  final int index;
  final bool keep;
}

class PropertyRequestFormSubmitted extends PropertyRequestFormEvent {
  const PropertyRequestFormSubmitted();
}

// State ---------------------------------------------------------------------

enum PropertyRequestFormStatus { loading, ready, submitting, submitted, failure }

class PropertyRequestFormState extends Equatable {
  const PropertyRequestFormState({
    this.status = PropertyRequestFormStatus.loading,
    this.isEdit = false,
    this.propertyId,
    this.error = false,
    this.propertyType = const [],
    this.propertyTypeOther = '',
    this.khatianNo = '',
    this.dagNoCs = '',
    this.dagNoRs = '',
    this.holdingNumber = '',
    this.landQuantity = '',
    this.myShareQuantity = '',
    this.ownership = '',
    this.coOwners = const [],
    this.existingDocs = const [],
    this.newDocs = const [],
    this.submitAttempted = false,
    this.submitError,
  });

  final PropertyRequestFormStatus status;
  final bool isEdit;
  final String? propertyId;
  final bool error;

  final List<String> propertyType;
  final String propertyTypeOther;
  final String khatianNo;
  final String dagNoCs;
  final String dagNoRs;
  final String holdingNumber;
  final String landQuantity;
  final String myShareQuantity;
  final String ownership;
  final List<FormCoOwnerRow> coOwners;
  final List<FormDocRow> existingDocs;
  final List<FormDocRow> newDocs;
  final bool submitAttempted;
  final String? submitError;

  bool get propertyTypeMissing => submitAttempted && propertyType.isEmpty;
  bool get khatianNoMissing => submitAttempted && khatianNo.trim().isEmpty;
  bool get dagNoCsMissing => submitAttempted && dagNoCs.trim().isEmpty;
  bool get dagNoRsMissing => submitAttempted && dagNoRs.trim().isEmpty;
  bool get landQuantityMissing => submitAttempted && landQuantity.trim().isEmpty;
  bool get landQuantityInvalid =>
      submitAttempted && landQuantity.trim().isNotEmpty && !_positive(landQuantity);
  bool get myShareQuantityMissing => submitAttempted && myShareQuantity.trim().isEmpty;
  bool get myShareQuantityInvalid =>
      submitAttempted && myShareQuantity.trim().isNotEmpty && !_positive(myShareQuantity);
  bool get ownershipMissing => submitAttempted && ownership.trim().isEmpty;
  bool get coOwnersInvalid => submitAttempted &&
      coOwners.any((c) => c.ownerName.trim().isEmpty || c.ownerPhone.trim().isEmpty);
  bool get docsInvalid => submitAttempted && newDocs.any((d) => d.isIncomplete || d.error != null);

  bool get formValid =>
      propertyType.isNotEmpty &&
      khatianNo.trim().isNotEmpty &&
      dagNoCs.trim().isNotEmpty &&
      dagNoRs.trim().isNotEmpty &&
      landQuantity.trim().isNotEmpty &&
      _positive(landQuantity) &&
      myShareQuantity.trim().isNotEmpty &&
      _positive(myShareQuantity) &&
      ownership.trim().isNotEmpty &&
      !coOwnersInvalid &&
      !docsInvalid;

  static bool _positive(String v) =>
      RegExp(r'^\d+(\.\d+)?$').hasMatch(v.trim()) && num.tryParse(v.trim())! > 0;

  PropertyRequestFormState copyWith({
    PropertyRequestFormStatus? status,
    bool? isEdit,
    String? propertyId,
    bool clearError = false,
    bool? error,
    List<String>? propertyType,
    String? propertyTypeOther,
    String? khatianNo,
    String? dagNoCs,
    String? dagNoRs,
    String? holdingNumber,
    String? landQuantity,
    String? myShareQuantity,
    String? ownership,
    List<FormCoOwnerRow>? coOwners,
    List<FormDocRow>? existingDocs,
    List<FormDocRow>? newDocs,
    bool? submitAttempted,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return PropertyRequestFormState(
      status: status ?? this.status,
      isEdit: isEdit ?? this.isEdit,
      propertyId: propertyId ?? this.propertyId,
      error: clearError ? false : (error ?? this.error),
      propertyType: propertyType ?? this.propertyType,
      propertyTypeOther: propertyTypeOther ?? this.propertyTypeOther,
      khatianNo: khatianNo ?? this.khatianNo,
      dagNoCs: dagNoCs ?? this.dagNoCs,
      dagNoRs: dagNoRs ?? this.dagNoRs,
      holdingNumber: holdingNumber ?? this.holdingNumber,
      landQuantity: landQuantity ?? this.landQuantity,
      myShareQuantity: myShareQuantity ?? this.myShareQuantity,
      ownership: ownership ?? this.ownership,
      coOwners: coOwners ?? this.coOwners,
      existingDocs: existingDocs ?? this.existingDocs,
      newDocs: newDocs ?? this.newDocs,
      submitAttempted: submitAttempted ?? this.submitAttempted,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }

  @override
  List<Object?> get props => [
        status, isEdit, propertyId, error, propertyType, propertyTypeOther,
        khatianNo, dagNoCs, dagNoRs, holdingNumber, landQuantity,
        myShareQuantity, ownership, coOwners, existingDocs, newDocs,
        submitAttempted, submitError,
      ];
}

class PropertyRequestFormBloc
    extends Bloc<PropertyRequestFormEvent, PropertyRequestFormState> {
  PropertyRequestFormBloc({MemberRepository? repository})
      : _repository = repository ?? MemberRepository(apiClient: sl<ApiClient>()),
        super(const PropertyRequestFormState()) {
    on<PropertyRequestFormInitialized>(_onInitialized);
    on<PropertyRequestFormFieldChanged>(_onFieldChanged);
    on<PropertyRequestFormCoOwnerAdded>(_onCoOwnerAdded);
    on<PropertyRequestFormCoOwnerRemoved>(_onCoOwnerRemoved);
    on<PropertyRequestFormCoOwnerChanged>(_onCoOwnerChanged);
    on<PropertyRequestFormDocAdded>(_onDocAdded);
    on<PropertyRequestFormDocRemoved>(_onDocRemoved);
    on<PropertyRequestFormDocChanged>(_onDocChanged);
    on<PropertyRequestFormExistingDocKeepChanged>(_onExistingDocKeepChanged);
    on<PropertyRequestFormSubmitted>(_onSubmitted);
  }

  final MemberRepository _repository;

  Future<void> _onInitialized(
    PropertyRequestFormInitialized event,
    Emitter<PropertyRequestFormState> emit,
  ) async {
    final propertyId = event.propertyId;
    if (propertyId == null || propertyId.isEmpty) {
      emit(state.copyWith(
        status: PropertyRequestFormStatus.ready,
        isEdit: false,
        clearError: true,
      ));
      return;
    }
    // Edit mode: prefill from the member's profile property (Angular idiom).
    emit(state.copyWith(
      status: PropertyRequestFormStatus.loading,
      isEdit: true,
      propertyId: propertyId,
      clearError: true,
    ));
    try {
      final profile = await _repository.getProfile();
      MemberProperty? property;
      for (final p in profile.properties) {
        if (p.id == propertyId) property = p;
      }
      if (property == null) {
        emit(state.copyWith(status: PropertyRequestFormStatus.failure, error: true));
        return;
      }
      emit(state.copyWith(
        status: PropertyRequestFormStatus.ready,
        propertyType: property.propertyType,
        propertyTypeOther: property.propertyTypeOther ?? '',
        khatianNo: property.khatianNo ?? '',
        dagNoCs: property.dagNoCs ?? '',
        dagNoRs: property.dagNoRs ?? '',
        holdingNumber: property.holdingNumber ?? '',
        landQuantity: property.landQuantity ?? '',
        myShareQuantity: property.myShareQuantity ?? '',
        ownership: property.ownership ?? '',
        coOwners: [
          for (final c in property.coOwners)
            FormCoOwnerRow(ownerName: c.ownerName, ownerPhone: c.ownerPhone),
        ],
        existingDocs: [
          for (final d in property.applicableDocs)
            FormDocRow(docType: d.docType, filePath: d.filePath, keep: true),
        ],
      ));
    } on ApiException {
      emit(state.copyWith(status: PropertyRequestFormStatus.failure, error: true));
    }
  }

  void _onFieldChanged(
    PropertyRequestFormFieldChanged event,
    Emitter<PropertyRequestFormState> emit,
  ) {
    emit(state.copyWith(
      propertyType: event.propertyType,
      propertyTypeOther: event.propertyTypeOther,
      khatianNo: event.khatianNo,
      dagNoCs: event.dagNoCs,
      dagNoRs: event.dagNoRs,
      holdingNumber: event.holdingNumber,
      landQuantity: event.landQuantity,
      myShareQuantity: event.myShareQuantity,
      ownership: event.ownership,
      clearSubmitError: true,
    ));
  }

  void _onCoOwnerAdded(
    PropertyRequestFormCoOwnerAdded event,
    Emitter<PropertyRequestFormState> emit,
  ) {
    emit(state.copyWith(coOwners: [...state.coOwners, const FormCoOwnerRow()]));
  }

  void _onCoOwnerRemoved(
    PropertyRequestFormCoOwnerRemoved event,
    Emitter<PropertyRequestFormState> emit,
  ) {
    final rows = [...state.coOwners]..removeAt(event.index);
    emit(state.copyWith(coOwners: rows));
  }

  void _onCoOwnerChanged(
    PropertyRequestFormCoOwnerChanged event,
    Emitter<PropertyRequestFormState> emit,
  ) {
    final rows = [...state.coOwners];
    if (event.index < 0 || event.index >= rows.length) return;
    rows[event.index] = event.row;
    emit(state.copyWith(coOwners: rows));
  }

  void _onDocAdded(
    PropertyRequestFormDocAdded event,
    Emitter<PropertyRequestFormState> emit,
  ) {
    emit(state.copyWith(newDocs: [...state.newDocs, const FormDocRow(docType: '')]));
  }

  void _onDocRemoved(
    PropertyRequestFormDocRemoved event,
    Emitter<PropertyRequestFormState> emit,
  ) {
    final rows = [...state.newDocs]..removeAt(event.index);
    emit(state.copyWith(newDocs: rows));
  }

  void _onDocChanged(
    PropertyRequestFormDocChanged event,
    Emitter<PropertyRequestFormState> emit,
  ) {
    final rows = [...state.newDocs];
    if (event.index < 0 || event.index >= rows.length) return;
    rows[event.index] = event.row;
    emit(state.copyWith(newDocs: rows));
  }

  void _onExistingDocKeepChanged(
    PropertyRequestFormExistingDocKeepChanged event,
    Emitter<PropertyRequestFormState> emit,
  ) {
    final rows = [...state.existingDocs];
    if (event.index < 0 || event.index >= rows.length) return;
    rows[event.index] = rows[event.index].copyWith(keep: event.keep);
    emit(state.copyWith(existingDocs: rows));
  }

  Future<void> _onSubmitted(
    PropertyRequestFormSubmitted event,
    Emitter<PropertyRequestFormState> emit,
  ) async {
    emit(state.copyWith(submitAttempted: true, clearSubmitError: true));
    if (!state.formValid) return;
    emit(state.copyWith(status: PropertyRequestFormStatus.submitting));
    try {
      final docs = [
        // Kept existing docs first, then new uploads, in stable order.
        for (final row in state.existingDocs)
          if (row.keep && row.filePath != null)
            PropertyRequestDocsEntry(docType: row.docType, keepPath: row.filePath),
        for (final row in state.newDocs)
          PropertyRequestDocsEntry(docType: row.docType, keepPath: null),
      ];
      final files = <AttachedFileBytes>[];
      for (final row in state.newDocs) {
        final path = row.localPath;
        if (path == null) continue;
        final fileName = path.split(Platform.pathSeparator).last.split('/').last;
        final prepared = await prepareAnyFile(path, fileName);
        files.add(AttachedFileBytes(
          bytes: await File(prepared.path).readAsBytes(),
          fileName: prepared.fileName,
          contentType: DioMediaType.parse(prepared.mimeType),
        ));
      }
      await _repository.createPropertyRequest(PropertyRequestInput(
        action: state.isEdit ? PropertyRequestAction.edit : PropertyRequestAction.add,
        propertyId: state.isEdit ? state.propertyId : null,
        payload: PropertyRequestPayload(
          propertyType: state.propertyType,
          propertyTypeOther: state.propertyTypeOther.trim().isEmpty
              ? null
              : state.propertyTypeOther.trim(),
          khatianNo: state.khatianNo.trim(),
          dagNoCs: state.dagNoCs.trim(),
          dagNoRs: state.dagNoRs.trim(),
          holdingNumber: state.holdingNumber.trim(),
          landQuantity: state.landQuantity.trim(),
          myShareQuantity: state.myShareQuantity.trim(),
          ownership: state.ownership,
          coOwners: [
            for (final c in state.coOwners)
              if (c.ownerName.trim().isNotEmpty)
                PropertyRequestCoOwner(
                  ownerName: c.ownerName.trim(),
                  ownerPhone: c.ownerPhone.trim(),
                ),
          ],
          docs: docs,
        ),
        newDocFiles: files,
      ));
      emit(state.copyWith(status: PropertyRequestFormStatus.submitted));
    } on FileTooLargeError {
      emit(state.copyWith(
        status: PropertyRequestFormStatus.ready,
        submitError: 'docFileSizeError',
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: PropertyRequestFormStatus.ready,
        submitError: e.isBusiness && e.businessMessage != null
            ? e.businessMessage
            : 'submitFailed',
      ));
    }
  }
}

