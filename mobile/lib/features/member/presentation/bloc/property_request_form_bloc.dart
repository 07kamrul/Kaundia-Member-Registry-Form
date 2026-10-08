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

part 'property_request_form_event.dart';
part 'property_request_form_state.dart';

class PropertyRequestFormBloc
    extends Bloc<PropertyRequestFormEvent, PropertyRequestFormState> {
  PropertyRequestFormBloc({MemberRepository? repository})
      : _repository =
            repository ?? MemberRepository(apiClient: sl<ApiClient>()),
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
        emit(state.copyWith(
            status: PropertyRequestFormStatus.failure, error: true));
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
      emit(state.copyWith(
          status: PropertyRequestFormStatus.failure, error: true));
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
    emit(state
        .copyWith(newDocs: [...state.newDocs, const FormDocRow(docType: '')]));
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
            PropertyRequestDocsEntry(
                docType: row.docType, keepPath: row.filePath),
        for (final row in state.newDocs)
          PropertyRequestDocsEntry(docType: row.docType, keepPath: null),
      ];
      final files = <AttachedFileBytes>[];
      for (final row in state.newDocs) {
        final path = row.localPath;
        if (path == null) continue;
        final fileName =
            path.split(Platform.pathSeparator).last.split('/').last;
        final prepared = await prepareAnyFile(path, fileName);
        files.add(AttachedFileBytes(
          bytes: await File(prepared.path).readAsBytes(),
          fileName: prepared.fileName,
          contentType: DioMediaType.parse(prepared.mimeType),
        ));
      }
      await _repository.createPropertyRequest(PropertyRequestInput(
        action: state.isEdit
            ? PropertyRequestAction.edit
            : PropertyRequestAction.add,
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
