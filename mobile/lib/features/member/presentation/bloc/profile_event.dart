part of 'profile_bloc.dart';

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
