part of 'profile_bloc.dart';

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
        (r) =>
            r.status == PropertyRequestStatus.pending &&
            r.propertyId == propertyId,
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
      photoPickedPath:
          clearPhotoPicked ? null : (photoPickedPath ?? this.photoPickedPath),
      photoInputError: clearPhotoInputError
          ? null
          : (photoInputError ?? this.photoInputError),
      photoUploadError: clearPhotoUploadError
          ? null
          : (photoUploadError ?? this.photoUploadError),
      requests: requests ?? this.requests,
      requestsLoading: requestsLoading ?? this.requestsLoading,
      requestsError:
          clearRequestsError ? null : (requestsError ?? this.requestsError),
      requestSuccess:
          clearRequestSuccess ? null : (requestSuccess ?? this.requestSuccess),
      requestActionError: clearRequestActionError
          ? null
          : (requestActionError ?? this.requestActionError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        profile,
        error,
        editing,
        draft,
        willRequeue,
        saving,
        saveError,
        photoPickedPath,
        photoInputError,
        photoUploadError,
        requests,
        requestsLoading,
        requestsError,
        requestSuccess,
        requestActionError,
      ];
}
