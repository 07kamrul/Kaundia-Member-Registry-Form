import 'dart:io';

import 'package:dio/dio.dart' show DioMediaType;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/utils/file_utils.dart';
import '../../data/member_repository.dart';
import '../../domain/member_entities.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => const [];
}

class ProfileLoaded extends ProfileEvent {
  const ProfileLoaded();
}

class ProfileEditStarted extends ProfileEvent {
  const ProfileEditStarted();
}

class ProfileEditCancelled extends ProfileEvent {
  const ProfileEditCancelled();
}

class ProfileDraftChanged extends ProfileEvent {
  const ProfileDraftChanged(this.draft);

  final MemberProfileUpdate draft;

  @override
  List<Object?> get props => [draft];
}

class ProfileSaved extends ProfileEvent {
  const ProfileSaved({required this.update, this.photoPath});

  final MemberProfileUpdate update;

  /// Locally picked photo path (compress + upload on save, Angular idiom).
  final String? photoPath;

  @override
  List<Object?> get props => [update, photoPath];
}

class ProfilePhotoRemoved extends ProfileEvent {
  const ProfilePhotoRemoved();
}

class ProfileRequestsLoaded extends ProfileEvent {
  const ProfileRequestsLoaded();
}

class ProfileRequestWithdrawn extends ProfileEvent {
  const ProfileRequestWithdrawn(this.requestId);

  final String requestId;

  @override
  List<Object?> get props => [requestId];
}

class ProfileRequestDeleteSubmitted extends ProfileEvent {
  const ProfileRequestDeleteSubmitted(this.propertyId);

  final String propertyId;

  @override
  List<Object?> get props => [propertyId];
}

class ProfileMessageCleared extends ProfileEvent {
  const ProfileMessageCleared();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum ProfileStatus { loading, loaded, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.loading,
    this.profile,
    this.error,
    this.editing = false,
    this.draft = const MemberProfileUpdate(),
    this.willRequeue = false,
    this.saving = false,
    this.saveError,
    this.photoPickedPath,
    this.photoInputError,
    this.photoUploadError,
    this.requests = const [],
    this.requestsLoading = false,
    this.requestsError,
    this.requestSuccess,
    this.requestActionError,
  });

  final ProfileStatus status;
  final MemberProfile? profile;
  final String? error;
  final bool editing;
  final MemberProfileUpdate draft;

  /// True when the current draft's core-field edits will re-queue the approved
  /// profile for review (mirrors Angular willRequeue).
  final bool willRequeue;
  final bool saving;
  final String? saveError;
  final String? photoPickedPath;
  final String? photoInputError;
  final String? photoUploadError;
  final List<MemberPropertyRequest> requests;
  final bool requestsLoading;
  final String? requestsError;
  final String? requestSuccess;
  final String? requestActionError;

  bool hasPendingRequest(String propertyId) => requests.any(
        (r) => r.status == PropertyRequestStatus.pending && r.propertyId == propertyId,
      );

  ProfileState copyWith({
    ProfileStatus? status,
    MemberProfile? profile,
    String? error,
    bool clearError = false,
    bool? editing,
    MemberProfileUpdate? draft,
    bool? willRequeue,
    bool? saving,
    String? saveError,
    bool clearSaveError = false,
    String? photoPickedPath,
    bool clearPhotoPicked = false,
    String? photoInputError,
    bool clearPhotoInputError = false,
    String? photoUploadError,
    bool clearPhotoUploadError = false,
    List<MemberPropertyRequest>? requests,
    bool? requestsLoading,
    String? requestsError,
    bool clearRequestsError = false,
    String? requestSuccess,
    bool clearRequestSuccess = false,
    String? requestActionError,
    bool clearRequestActionError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: clearError ? null : (error ?? this.error),
      editing: editing ?? this.editing,
      draft: draft ?? this.draft,
      willRequeue: willRequeue ?? this.willRequeue,
      saving: saving ?? this.saving,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      photoPickedPath: clearPhotoPicked ? null : (photoPickedPath ?? this.photoPickedPath),
      photoInputError: clearPhotoInputError ? null : (photoInputError ?? this.photoInputError),
      photoUploadError: clearPhotoUploadError ? null : (photoUploadError ?? this.photoUploadError),
      requests: requests ?? this.requests,
      requestsLoading: requestsLoading ?? this.requestsLoading,
      requestsError: clearRequestsError ? null : (requestsError ?? this.requestsError),
      requestSuccess: clearRequestSuccess ? null : (requestSuccess ?? this.requestSuccess),
      requestActionError:
          clearRequestActionError ? null : (requestActionError ?? this.requestActionError),
    );
  }

  @override
  List<Object?> get props => [
        status, profile, error, editing, draft, willRequeue, saving, saveError,
        photoPickedPath, photoInputError, photoUploadError, requests,
        requestsLoading, requestsError, requestSuccess, requestActionError,
      ];
}

/// Bloc for the member profile page (view + edit + property requests).
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({MemberRepository? repository})
      : _repository = repository ??
            MemberRepository(apiClient: sl<ApiClient>()),
        super(const ProfileState()) {
    on<ProfileLoaded>(_onLoaded);
    on<ProfileEditStarted>(_onEditStarted);
    on<ProfileEditCancelled>(_onEditCancelled);
    on<ProfileDraftChanged>(_onDraftChanged);
    on<ProfileSaved>(_onSaved);
    on<ProfilePhotoRemoved>(_onPhotoRemoved);
    on<ProfileRequestsLoaded>(_onRequestsLoaded);
    on<ProfileRequestWithdrawn>(_onWithdrawn);
    on<ProfileRequestDeleteSubmitted>(_onDeleteSubmitted);
    on<ProfileMessageCleared>(_onMessageCleared);
  }

  final MemberRepository _repository;

  Future<void> _onLoaded(
    ProfileLoaded event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      final profile = await _repository.getProfile();
      emit(state.copyWith(status: ProfileStatus.loaded, profile: profile, clearError: true));
      add(const ProfileRequestsLoaded());
    } on ApiException {
      emit(state.copyWith(status: ProfileStatus.failure, error: 'loadError'));
    }
  }

  void _onEditStarted(
    ProfileEditStarted event,
    Emitter<ProfileState> emit,
  ) {
    final p = state.profile;
    if (p == null) return;
    final draft = MemberProfileUpdate(
      fullName: p.fullName,
      fatherOrHusband: p.fatherOrHusband,
      mother: p.mother,
      dob: p.dob,
      nationality: p.nationality,
      occupation: p.occupation,
      nid: p.nid,
      gender: p.gender,
      permanentHouse: p.permanentHouse,
      permanentRoad: p.permanentRoad,
      permanentPostOffice: p.permanentPostOffice,
      permanentUpazila: p.permanentUpazila,
      permanentDistrict: p.permanentDistrict,
      permanentDivision: p.permanentDivision,
      currentHouse: p.currentHouse,
      currentRoad: p.currentRoad,
      currentPostOffice: p.currentPostOffice,
      currentUpazila: p.currentUpazila,
      currentDistrict: p.currentDistrict,
      currentDivision: p.currentDivision,
      mobile: p.mobile,
      email: p.email,
      urgentContactName: p.urgentContactName,
      urgentContactRelation: p.urgentContactRelation,
      urgentContactMobile: p.urgentContactMobile,
      urgentContactAddress: p.urgentContactAddress,
    );
    emit(state.copyWith(
      editing: true,
      draft: draft,
      clearSaveError: true,
      clearPhotoPicked: true,
      clearPhotoInputError: true,
      clearPhotoUploadError: true,
      willRequeue: _requeueFor(draft, p),
    ));
  }

  void _onEditCancelled(
    ProfileEditCancelled event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(
      editing: false,
      draft: const MemberProfileUpdate(),
      willRequeue: false,
      clearSaveError: true,
      clearPhotoPicked: true,
      clearPhotoInputError: true,
      clearPhotoUploadError: true,
    ));
  }

  void _onDraftChanged(
    ProfileDraftChanged event,
    Emitter<ProfileState> emit,
  ) {
    final p = state.profile;
    emit(state.copyWith(
      draft: event.draft,
      willRequeue: p == null ? false : _requeueFor(event.draft, p),
    ));
  }

  bool _requeueFor(MemberProfileUpdate draft, MemberProfile p) =>
      p.memberStatus == MemberStatus.approved && draft.touchesCoreFields(p);

  Future<void> _onSaved(
    ProfileSaved event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(saving: true, clearSaveError: true, clearPhotoUploadError: true));
    try {
      var profile = state.profile;
      // Photo upload goes first: on failure the text edits stay in draft.
      if (event.photoPath != null) {
        try {
          final compressed = await prepareImage(event.photoPath!);
          final prepared = compressed ??
              AttachedFile(
                path: event.photoPath!,
                fileName: event.photoPath!.split(Platform.pathSeparator).last,
                mimeType: 'image/jpeg',
              );
          final bytes = await File(prepared.path).readAsBytes();
          profile = await _repository.uploadPhoto(AttachedFileBytes(
            bytes: bytes,
            fileName: prepared.fileName,
            contentType: DioMediaType.parse(prepared.mimeType),
          ));
          emit(state.copyWith(
            profile: profile,
            clearPhotoPicked: true,
            clearPhotoInputError: true,
            clearPhotoUploadError: true,
          ));
        } on ApiException {
          emit(state.copyWith(
            saving: false,
            photoUploadError: 'photoUploadError',
          ));
          return;
        }
      }
      final updated = await _repository.updateProfile(event.update);
      emit(state.copyWith(
        profile: updated,
        editing: false,
        saving: false,
        draft: const MemberProfileUpdate(),
        willRequeue: false,
        clearSaveError: true,
        clearPhotoPicked: true,
      ));
    } on ApiException catch (e) {
      final fieldErrors = e.fieldErrors.values.toList();
      emit(state.copyWith(
        saving: false,
        saveError: e.isValidation && fieldErrors.isNotEmpty ? fieldErrors.first : 'saveError',
      ));
    }
  }

  void _onPhotoRemoved(
    ProfilePhotoRemoved event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(clearPhotoPicked: true, clearPhotoInputError: true));
  }

  Future<void> _onRequestsLoaded(
    ProfileRequestsLoaded event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(requestsLoading: true, clearRequestsError: true));
    try {
      final requests = await _repository.getPropertyRequests();
      emit(state.copyWith(requests: requests, requestsLoading: false, clearRequestsError: true));
    } on ApiException {
      emit(state.copyWith(requestsLoading: false, requestsError: 'loadFailed'));
    }
  }

  Future<void> _onWithdrawn(
    ProfileRequestWithdrawn event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(clearRequestActionError: true));
    try {
      await _repository.withdrawPropertyRequest(event.requestId);
      emit(state.copyWith(requestSuccess: 'withdrawnSuccess'));
      add(const ProfileRequestsLoaded());
    } on ApiException catch (e) {
      emit(state.copyWith(
        requestActionError:
            e.isBusiness ? e.businessMessage : 'withdrawFailed',
      ));
    }
  }

  Future<void> _onDeleteSubmitted(
    ProfileRequestDeleteSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(clearRequestActionError: true));
    try {
      await _repository.createPropertyRequest(PropertyRequestInput(
        action: PropertyRequestAction.delete,
        propertyId: event.propertyId,
        payload: const PropertyRequestPayload(
          propertyType: [],
          coOwners: [],
          docs: [],
        ),
      ));
      emit(state.copyWith(requestSuccess: 'successSent'));
      add(const ProfileRequestsLoaded());
    } on ApiException catch (e) {
      emit(state.copyWith(
        requestActionError: e.isBusiness ? e.businessMessage : 'submitFailed',
      ));
    }
  }

  void _onMessageCleared(
    ProfileMessageCleared event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(clearRequestSuccess: true, clearRequestActionError: true));
  }
}
