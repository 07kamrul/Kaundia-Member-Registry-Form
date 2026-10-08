import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injector.dart';
import '../../../core/enums/enums.dart';
import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/attachment_viewer.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/member_repository.dart';
import '../domain/member_entities.dart';
import '../presentation/bloc/profile_bloc.dart';

/// Port of Angular ProfileComponent: view mode (personal/contact/address/
/// payment/property/nominee sections), edit mode with the re-approval warning
/// for core fields, photo upload, and the property change-request list.
class ProfilePage extends StatelessWidget {
  final String? id;
  final String? propertyId;
  final String? returnUrl;

  const ProfilePage({super.key, this.id, this.propertyId, this.returnUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileBloc(repository: MemberRepository(apiClient: sl<ApiClient>()))
        ..add(const ProfileLoaded()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          final success = state.requestSuccess;
          if (success != null) {
            showAppToast(
              context,
              switch (success) {
                'withdrawnSuccess' => loc.memberPropertyRequestsWithdrawnSuccess,
                'successSent' => loc.memberPropertyRequestsSuccessSent,
                _ => success,
              },
            );
            context.read<ProfileBloc>().add(const ProfileMessageCleared());
          }
          final actionError = state.requestActionError;
          if (actionError != null) {
            showAppToast(
              context,
              switch (actionError) {
                'withdrawFailed' => loc.memberPropertyRequestsErrorsWithdrawFailed,
                'submitFailed' => loc.memberPropertyRequestsErrorsSubmitFailed,
                _ => actionError,
              },
              error: true,
            );
          }
          if (state.saveError != null) {
            showAppToast(
              context,
              state.saveError == 'saveError'
                  ? loc.memberProfileSaveError
                  : state.saveError!,
              error: true,
            );
          }
          if (state.photoUploadError != null) {
            showAppToast(context, loc.memberProfilePhotoUploadError, error: true);
          }
        },
        builder: (context, state) {
          final bloc = context.read<ProfileBloc>();
          final body = switch (state.status) {
            ProfileStatus.loading => const SkeletonLoader(lines: 8),
            ProfileStatus.failure => InlineError(
                message: loc.memberProfileLoadError,
                onRetry: () => bloc.add(const ProfileLoaded()),
              ),
            ProfileStatus.loaded => _loaded(context, state, loc, bloc),
          };
          return body;
        },
      ),
    );
  }

  Widget _loaded(
    BuildContext context,
    ProfileState state,
    AppLocalizations loc,
    ProfileBloc bloc,
  ) {
    final profile = state.profile!;
    if (state.editing) {
      return _ProfileEditView(profile: profile, state: state);
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        PageHeader(
          title: loc.memberProfileTitle,
          subtitle: profile.memberId,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _statusBadge(context, profile.memberStatus, loc),
            ),
          ],
        ),
        if (profile.memberStatus == MemberStatus.pending)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(loc.memberProfilePendingReviewNotice),
              ),
            ),
          ),
        // Photo + identity header.
        AppCard(
          child: Row(
            children: [
              _avatar(profile),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.fullName,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(profile.mobile),
                    if (profile.email != null) Text(profile.email!),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: AppButton(
            label: loc.memberProfileEditButton,
            icon: Icons.edit_outlined,
            onPressed: () => bloc.add(const ProfileEditStarted()),
          ),
        ),
        _section(context, loc.memberProfilePersonalInfoTitle, [
          _row(loc.memberProfileNameLabel, profile.fullName),
          _row(loc.memberProfileFatherOrHusbandLabel, profile.fatherOrHusband),
          _row(loc.memberProfileMotherLabel, profile.mother),
          _row(loc.memberProfileDobLabel, profile.dob),
          _row(loc.memberProfileNationalityLabel, profile.nationality),
          _row(loc.memberProfileNidLabel, profile.nid),
          _row(loc.memberProfileOccupationLabel, profile.occupation),
          _row(loc.memberProfileGenderLabel, profile.gender),
        ]),
        _section(context, loc.memberProfileContactTitle, [
          _row(loc.memberProfileMobileLabel, profile.mobile),
          _row(loc.memberProfileEmailLabel, profile.email),
          _row(loc.memberProfileAddressLabel, _address(profile.permanentHouse,
              profile.permanentRoad, profile.permanentPostOffice,
              profile.permanentUpazila, profile.permanentDistrict,
              profile.permanentDivision)),
          if (profile.hasCurrentAddress())
            _row(loc.memberProfileCurrentAddressLabel, _address(
                profile.currentHouse, profile.currentRoad,
                profile.currentPostOffice, profile.currentUpazila,
                profile.currentDistrict, profile.currentDivision)),
          _row(loc.memberProfileUrgentContactTitle,
              [profile.urgentContactName, profile.urgentContactRelation,
               profile.urgentContactMobile, profile.urgentContactAddress]
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .join(' · ')),
        ]),
        _section(context, loc.memberProfilePaymentTitle, [
          _row(loc.memberProfileAdmissionFeeLabel, profile.admissionFee),
          _row(loc.memberProfileSubscriptionLabel, profile.subscription),
          _row(loc.memberProfileReceiptNoLabel, profile.receiptNo),
          _row(loc.memberProfilePaymentMethodLabel, profile.paymentMethod),
          _row(loc.memberProfileSubmissionDateLabel, profile.submissionDate),
          if (profile.receiptPhotoUrl.isNotEmpty)
            _fileRow(context, loc.memberProfileReceiptPhotoLabel,
                profile.receiptPhotoUrl, loc),
        ]),
        _propertiesSection(context, profile, loc),
        if (profile.nominees.isEmpty)
          const SizedBox.shrink()
        else
          _section(
            context,
            loc.memberProfileNomineesTitle,
            [
              for (final n in profile.nominees)
                _row('${n.name} (${n.relation})', n.mobile),
            ],
          ),
        _requestsSection(context, state, loc),
      ],
    );
  }

  Widget _avatar(MemberProfile profile) {
    if (profile.memberPhotoUrl.isEmpty) {
      return CircleAvatar(
        radius: 32,
        child: Text(
          profile.fullName.trim().isEmpty ? '—' : profile.fullName.trim().charAt(0),
          style: const TextStyle(fontSize: 24),
        ),
      );
    }
    return CircleAvatar(
      radius: 32,
      backgroundImage: NetworkImage(profile.memberPhotoUrl),
      onBackgroundImageError: (_, __) {},
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> rows) {
    return AppCard(
      title: title,
      child: Column(children: rows),
    );
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _fileRow(
      BuildContext context, String label, String url, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 150, child: Text(label)),
          Expanded(
            child: TextButton.icon(
              onPressed: () => showAttachmentViewer(context, rawPathOrUrl: url, title: label),
              icon: const Icon(Icons.attach_file, size: 18),
              label: Text(loc.memberProfileViewFile),
            ),
          ),
        ],
      ),
    );
  }

  String _address(String? house, String? road, String? postOffice,
      String? upazila, String? district, String? division) {
    return [
      house, road, postOffice, upazila, district, division,
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
  }

  Widget _propertiesSection(
      BuildContext context, MemberProfile profile, AppLocalizations loc) {
    if (profile.properties.isEmpty) {
      return AppCard(
        title: loc.memberProfilePropertyTitle,
        child: Text(loc.memberProfileNoPropertyInfo),
      );
    }
    return AppCard(
      title: loc.memberProfilePropertyTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final property in profile.properties) ...[
            Text(
              '${loc.memberProfilePropertyItemLabel} #${property.id}',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            _row(
              loc.memberProfilePropertyTypesLabel,
              [...property.propertyType, property.propertyTypeOther]
                  .whereType<String>()
                  .where((s) => s.isNotEmpty)
                  .join(' / '),
            ),
            _row(loc.memberProfileKhatianLabel, property.khatianNo),
            _row(loc.memberProfileDagNoCsLabel, property.dagNoCs),
            _row(loc.memberProfileDagNoRsLabel, property.dagNoRs),
            _row(loc.memberProfileHoldingNumberLabel, property.holdingNumber),
            _row(loc.memberProfileLandQuantityLabel, property.landQuantity),
            _row(loc.memberProfileMyShareQuantityLabel, property.myShareQuantity),
            _row(loc.memberProfileOwnershipLabel, property.ownership),
            if (property.coOwners.isNotEmpty)
              _row(
                loc.memberProfileCoOwnerLabel,
                property.coOwners
                    .map((c) => '${c.ownerName} (${c.ownerPhone})')
                    .join(', '),
              ),
            if (property.applicableDocs.isNotEmpty)
              for (final doc in property.applicableDocs)
                if (doc.fileUrl != null)
                  _fileRow(context, doc.docType, doc.fileUrl!, loc),
            const Divider(),
          ],
        ],
      ),
    );
  }

  Widget _requestsSection(
      BuildContext context, ProfileState state, AppLocalizations loc) {
    return AppCard(
      title: loc.memberPropertyRequestsListTitle,
      trailing: TextButton(
        onPressed: () => context.go('/property-requests/new'),
        child: Text(loc.memberPropertyRequestsAddButton),
      ),
      child: state.requestsLoading
          ? const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            )
          : state.requestsError != null
              ? InlineError(
                  message: loc.memberPropertyRequestsErrorsLoadFailed,
                  onRetry: () =>
                      context.read<ProfileBloc>().add(const ProfileRequestsLoaded()),
                )
              : state.requests.isEmpty
                  ? Text(loc.memberPropertyRequestsNoRequests)
                  : Column(
                      children: [
                        for (final request in state.requests)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(request.reference),
                            subtitle: Text(
                              '${requestActionLabel(request.action, loc)} · ${requestStatusLabel(request.status, loc)}',
                            ),
                            trailing: request.status == PropertyRequestStatus.pending
                                ? TextButton(
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text(loc.memberPropertyRequestsWithdrawModalTitle),
                                          content: Text(loc.memberPropertyRequestsWithdrawModalMessage),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(false),
                                              child: Text(loc.commonCancel),
                                            ),
                                            FilledButton(
                                              onPressed: () => Navigator.of(ctx).pop(true),
                                              child: Text(
                                                  loc.memberPropertyRequestsWithdrawModalConfirmLabel),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true && context.mounted) {
                                        context
                                            .read<ProfileBloc>()
                                            .add(ProfileRequestWithdrawn(request.id));
                                      }
                                    },
                                    child: Text(loc.memberPropertyRequestsWithdrawButton),
                                  )
                                : null,
                          ),
                      ],
                    ),
  );
  }
}

String requestActionLabel(PropertyRequestAction action, AppLocalizations loc) =>
    switch (action) {
      PropertyRequestAction.add => loc.memberPropertyRequestsActionsAdd,
      PropertyRequestAction.edit => loc.memberPropertyRequestsActionsEdit,
      PropertyRequestAction.delete => loc.memberPropertyRequestsActionsDelete,
      PropertyRequestAction.unknown => action.name,
    };

String requestStatusLabel(PropertyRequestStatus status, AppLocalizations loc) =>
    switch (status) {
      PropertyRequestStatus.pending => loc.memberPropertyRequestsStatusLabelsPending,
      PropertyRequestStatus.approved =>
        loc.memberPropertyRequestsStatusLabelsApproved,
      PropertyRequestStatus.cancelled =>
        loc.memberPropertyRequestsStatusLabelsCancelled,
      PropertyRequestStatus.unknown => status.name,
    };

class _ProfileEditView extends StatefulWidget {
  const _ProfileEditView({required this.profile, required this.state});

  final MemberProfile profile;
  final ProfileState state;

  @override
  State<_ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<_ProfileEditView> {
  late final Map<String, TextEditingController> _controllers = {
    for (final key in _fieldKeys)
      key: TextEditingController(text: _initial(key)),
  };
  String? _photoPath;

  static const _fieldKeys = [
    'fullName', 'fatherOrHusband', 'mother', 'dob', 'nationality', 'occupation',
    'nid', 'gender', 'permanentHouse', 'permanentRoad', 'permanentPostOffice',
    'permanentUpazila', 'permanentDistrict', 'permanentDivision',
    'currentHouse', 'currentRoad', 'currentPostOffice', 'currentUpazila',
    'currentDistrict', 'currentDivision', 'mobile', 'email',
    'urgentContactName', 'urgentContactRelation', 'urgentContactMobile',
    'urgentContactAddress',
  ];

  String? _initial(String key) => switch (key) {
        'fullName' => widget.profile.fullName,
        'fatherOrHusband' => widget.profile.fatherOrHusband,
        'mother' => widget.profile.mother,
        'dob' => widget.profile.dob,
        'nationality' => widget.profile.nationality,
        'occupation' => widget.profile.occupation,
        'nid' => widget.profile.nid,
        'gender' => widget.profile.gender,
        'permanentHouse' => widget.profile.permanentHouse,
        'permanentRoad' => widget.profile.permanentRoad,
        'permanentPostOffice' => widget.profile.permanentPostOffice,
        'permanentUpazila' => widget.profile.permanentUpazila,
        'permanentDistrict' => widget.profile.permanentDistrict,
        'permanentDivision' => widget.profile.permanentDivision,
        'currentHouse' => widget.profile.currentHouse,
        'currentRoad' => widget.profile.currentRoad,
        'currentPostOffice' => widget.profile.currentPostOffice,
        'currentUpazila' => widget.profile.currentUpazila,
        'currentDistrict' => widget.profile.currentDistrict,
        'currentDivision' => widget.profile.currentDivision,
        'mobile' => widget.profile.mobile,
        'email' => widget.profile.email,
        'urgentContactName' => widget.profile.urgentContactName,
        'urgentContactRelation' => widget.profile.urgentContactRelation,
        'urgentContactMobile' => widget.profile.urgentContactMobile,
        'urgentContactAddress' => widget.profile.urgentContactAddress,
        _ => null,
      } ??
      '';

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncDraft(BuildContext context) {
    context.read<ProfileBloc>().add(ProfileDraftChanged(MemberProfileUpdate(
          fullName: _controllers['fullName']!.text,
          fatherOrHusband: _controllers['fatherOrHusband']!.text,
          mother: _controllers['mother']!.text,
          dob: _controllers['dob']!.text,
          nationality: _emptyToNull(_controllers['nationality']!.text),
          occupation: _emptyToNull(_controllers['occupation']!.text),
          nid: _emptyToNull(_controllers['nid']!.text),
          gender: _emptyToNull(_controllers['gender']!.text),
          permanentHouse: _emptyToNull(_controllers['permanentHouse']!.text),
          permanentRoad: _emptyToNull(_controllers['permanentRoad']!.text),
          permanentPostOffice: _emptyToNull(_controllers['permanentPostOffice']!.text),
          permanentUpazila: _emptyToNull(_controllers['permanentUpazila']!.text),
          permanentDistrict: _emptyToNull(_controllers['permanentDistrict']!.text),
          permanentDivision: _emptyToNull(_controllers['permanentDivision']!.text),
          currentHouse: _emptyToNull(_controllers['currentHouse']!.text),
          currentRoad: _emptyToNull(_controllers['currentRoad']!.text),
          currentPostOffice: _emptyToNull(_controllers['currentPostOffice']!.text),
          currentUpazila: _emptyToNull(_controllers['currentUpazila']!.text),
          currentDistrict: _emptyToNull(_controllers['currentDistrict']!.text),
          currentDivision: _emptyToNull(_controllers['currentDivision']!.text),
          mobile: _controllers['mobile']!.text,
          email: _emptyToNull(_controllers['email']!.text),
          urgentContactName: _emptyToNull(_controllers['urgentContactName']!.text),
          urgentContactRelation:
              _emptyToNull(_controllers['urgentContactRelation']!.text),
          urgentContactMobile:
              _emptyToNull(_controllers['urgentContactMobile']!.text),
          urgentContactAddress:
              _emptyToNull(_controllers['urgentContactAddress']!.text),
        )));
  }

  String? _emptyToNull(String v) => v.trim().isEmpty ? null : v.trim();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<ProfileBloc>();
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        PageHeader(title: loc.memberProfileEditTitle),
        if (widget.state.willRequeue)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_outlined,
                        color: Theme.of(context).colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(loc.memberProfileRequeueWarning)),
                  ],
                ),
              ),
            ),
          ),
        // Photo pick/remove (uploaded on save).
        AppCard(
          title: loc.memberProfilePhotoLabel,
          child: Column(
            children: [
              if (_photoPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_photoPath!),
                    height: 120,
                    errorBuilder: (_, __, ___) => const SizedBox(height: 120),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppButton(
                    label: loc.memberProfileChangePhotoButton,
                    variant: AppButtonVariant.secondary,
                    icon: Icons.photo_camera_outlined,
                    onPressed: () async {
                      final picked =
                          await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) setState(() => _photoPath = picked.path);
                    },
                  ),
                  if (_photoPath != null) ...[
                    const SizedBox(width: 8),
                    AppButton(
                      label: loc.memberProfileRemovePhotoButton,
                      variant: AppButtonVariant.ghost,
                      onPressed: () => setState(() => _photoPath = null),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        AppCard(
          title: loc.memberProfilePersonalInfoTitle,
          child: Column(
            children: [
              for (final key in [
                'fullName', 'fatherOrHusband', 'mother', 'dob', 'nationality',
                'occupation', 'nid', 'gender',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _controllers[key],
                    onChanged: (_) => _syncDraft(context),
                    decoration: InputDecoration(
                      labelText: _labelFor(key, loc),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
        ),
        AppCard(
          title: loc.memberProfileAddressTitle,
          child: Column(
            children: [
              for (final key in [
                'permanentHouse', 'permanentRoad', 'permanentPostOffice',
                'permanentUpazila', 'permanentDistrict', 'permanentDivision',
                'currentHouse', 'currentRoad', 'currentPostOffice',
                'currentUpazila', 'currentDistrict', 'currentDivision',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _controllers[key],
                    onChanged: (_) => _syncDraft(context),
                    decoration: InputDecoration(
                      labelText: _labelFor(key, loc),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
        ),
        AppCard(
          title: loc.memberProfileContactTitle,
          child: Column(
            children: [
              for (final key in [
                'mobile', 'email', 'urgentContactName', 'urgentContactRelation',
                'urgentContactMobile', 'urgentContactAddress',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _controllers[key],
                    keyboardType: key == 'mobile' || key == 'urgentContactMobile'
                        ? TextInputType.phone
                        : null,
                    onChanged: (_) => _syncDraft(context),
                    decoration: InputDecoration(
                      labelText: _labelFor(key, loc),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: loc.memberProfileCancelButton,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => bloc.add(const ProfileEditCancelled()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, state) => AppButton(
                    label: state.saving
                        ? loc.commonLoading
                        : loc.memberProfileSaveButton,
                    onPressed: state.saving
                        ? null
                        : () {
                            _syncDraft(context);
                            final mobile =
                                _controllers['mobile']!.text.trim();
                            if (mobile.isNotEmpty &&
                                !RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(mobile)) {
                              showAppToast(
                                  context, loc.memberProfileMobileInvalid,
                                  error: true);
                              return;
                            }
                            bloc.add(ProfileSaved(
                              update: context
                                  .read<ProfileBloc>()
                                  .state
                                  .draft,
                              photoPath: _photoPath,
                            ));
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _labelFor(String key, AppLocalizations loc) => switch (key) {
        'fullName' => loc.memberProfileNameLabel,
        'fatherOrHusband' => loc.memberProfileFatherOrHusbandLabel,
        'mother' => loc.memberProfileMotherLabel,
        'dob' => loc.memberProfileDobLabel,
        'nationality' => loc.memberProfileNationalityLabel,
        'occupation' => loc.memberProfileOccupationLabel,
        'nid' => loc.memberProfileNidLabel,
        'gender' => loc.memberProfileGenderLabel,
        'permanentHouse' => loc.memberProfileHouseLabel,
        'permanentRoad' => loc.memberProfileRoadLabel,
        'permanentPostOffice' => loc.memberProfilePostOfficeLabel,
        'permanentUpazila' => loc.memberProfileUpazilaLabel,
        'permanentDistrict' => loc.memberProfileDistrictLabel,
        'permanentDivision' => loc.memberProfileDivisionLabel,
        'currentHouse' => loc.memberProfileCurrentHouseLabel,
        'currentRoad' => loc.memberProfileCurrentRoadLabel,
        'currentPostOffice' => loc.memberProfileCurrentPostOfficeLabel,
        'currentUpazila' => loc.memberProfileCurrentUpazilaLabel,
        'currentDistrict' => loc.memberProfileCurrentDistrictLabel,
        'currentDivision' => loc.memberProfileCurrentDivisionLabel,
        'mobile' => loc.memberProfileMobileLabel,
        'email' => loc.memberProfileEmailLabel,
        'urgentContactName' => loc.memberProfileUrgentNameLabel,
        'urgentContactRelation' => loc.memberProfileRelationLabel,
        'urgentContactMobile' => loc.memberProfileUrgentMobileLabel,
        'urgentContactAddress' => loc.memberProfileAddressLabel,
        _ => key,
      };
}

extension _StringX on String {
  String charAt(int index) => substring(index, index + 1);
}

Widget _statusBadge(BuildContext context, MemberStatus status, AppLocalizations loc) {
  final (kind, label) = switch (status) {
    MemberStatus.approved => (StatusKind.approved, loc.memberProfileStatusApproved),
    MemberStatus.rejected => (StatusKind.rejected, loc.memberProfileStatusRejected),
    _ => (StatusKind.pending, loc.memberProfileStatusPending),
  };
  return StatusBadge(kind: kind, label: label);
}
