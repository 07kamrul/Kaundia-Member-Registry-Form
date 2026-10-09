import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/member_entities.dart';
import '../bloc/profile_bloc.dart';
import 'member_ui.dart';
import 'profile_sections.dart';

/// Edit mode of the member profile: photo pick, personal / address / contact
/// fields and a sticky save bar. Every change is mirrored into the bloc draft.
class ProfileEditView extends StatefulWidget {
  const ProfileEditView({super.key, required this.profile, required this.state});

  final MemberProfile profile;
  final ProfileState state;

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

const _personalKeys = [
  'fullName', 'fatherOrHusband', 'mother', 'dob', 'nationality', 'occupation', 'nid', 'gender',
];
const _permanentKeys = [
  'permanentHouse', 'permanentRoad', 'permanentPostOffice',
  'permanentUpazila', 'permanentDistrict', 'permanentDivision',
];
const _currentKeys = [
  'currentHouse', 'currentRoad', 'currentPostOffice',
  'currentUpazila', 'currentDistrict', 'currentDivision',
];
const _contactKeys = [
  'mobile', 'email', 'urgentContactName', 'urgentContactRelation',
  'urgentContactMobile', 'urgentContactAddress',
];

class _ProfileEditViewState extends State<ProfileEditView> {
  late final Map<String, TextEditingController> _controllers = {
    for (final key in [..._personalKeys, ..._permanentKeys, ..._currentKeys, ..._contactKeys])
      key: TextEditingController(text: _initial(key)),
  };
  String? _photoPath;
  late bool _showInNeighbourDirectory = widget.profile.showInNeighbourDirectory;

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

  String _text(String key) => _controllers[key]!.text;

  String? _emptyToNull(String v) => v.trim().isEmpty ? null : v.trim();

  void _syncDraft(BuildContext context) {
    context.read<ProfileBloc>().add(ProfileDraftChanged(MemberProfileUpdate(
          fullName: _text('fullName'),
          fatherOrHusband: _text('fatherOrHusband'),
          mother: _text('mother'),
          dob: _text('dob'),
          nationality: _emptyToNull(_text('nationality')),
          occupation: _emptyToNull(_text('occupation')),
          nid: _emptyToNull(_text('nid')),
          gender: _emptyToNull(_text('gender')),
          permanentHouse: _emptyToNull(_text('permanentHouse')),
          permanentRoad: _emptyToNull(_text('permanentRoad')),
          permanentPostOffice: _emptyToNull(_text('permanentPostOffice')),
          permanentUpazila: _emptyToNull(_text('permanentUpazila')),
          permanentDistrict: _emptyToNull(_text('permanentDistrict')),
          permanentDivision: _emptyToNull(_text('permanentDivision')),
          currentHouse: _emptyToNull(_text('currentHouse')),
          currentRoad: _emptyToNull(_text('currentRoad')),
          currentPostOffice: _emptyToNull(_text('currentPostOffice')),
          currentUpazila: _emptyToNull(_text('currentUpazila')),
          currentDistrict: _emptyToNull(_text('currentDistrict')),
          currentDivision: _emptyToNull(_text('currentDivision')),
          mobile: _text('mobile'),
          email: _emptyToNull(_text('email')),
          urgentContactName: _emptyToNull(_text('urgentContactName')),
          urgentContactRelation: _emptyToNull(_text('urgentContactRelation')),
          urgentContactMobile: _emptyToNull(_text('urgentContactMobile')),
          urgentContactAddress: _emptyToNull(_text('urgentContactAddress')),
          showInNeighbourDirectory: _showInNeighbourDirectory,
        )));
  }

  void _save(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bloc = context.read<ProfileBloc>();
    _syncDraft(context);
    final mobile = _text('mobile').trim();
    if (mobile.isNotEmpty && !RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(mobile)) {
      showAppToast(context, loc.memberProfileMobileInvalid, error: true);
      return;
    }
    bloc.add(ProfileSaved(update: bloc.state.draft, photoPath: _photoPath));
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: PageBody(
            maxWidth: Breakpoints.formMaxWidth,
            children: [
              PageHeader(title: loc.memberProfileEditTitle, icon: Icons.manage_accounts_outlined),
              if (widget.state.willRequeue)
                NoticeBanner(tone: NoticeTone.warning, message: loc.memberProfileRequeueWarning),
              _photoCard(loc),
              _fieldsCard(loc.memberProfilePersonalInfoTitle, _personalKeys, loc),
              _addressCard(loc),
              _fieldsCard(loc.memberProfileContactTitle, _contactKeys, loc),
              _neighbourDirectoryCard(loc),
            ],
          ),
        ),
        _SaveBar(onCancel: () => context.read<ProfileBloc>().add(const ProfileEditCancelled()), onSave: () => _save(context)),
      ],
    );
  }

  Widget _photoCard(AppLocalizations loc) {
    return AppCard(
      title: loc.memberProfilePhotoLabel,
      child: Row(
        children: [
          ProfileAvatar(
            profile: widget.profile,
            radius: 36,
            localImage: _photoPath == null ? null : FileImage(File(_photoPath!)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  label: loc.memberProfileChangePhotoButton,
                  variant: AppButtonVariant.secondary,
                  icon: Icons.photo_camera_outlined,
                  onPressed: _pickPhoto,
                ),
                if (_photoPath != null)
                  AppButton(
                    label: loc.memberProfileRemovePhotoButton,
                    variant: AppButtonVariant.ghost,
                    icon: Icons.close,
                    onPressed: () => setState(() => _photoPath = null),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _neighbourDirectoryCard(AppLocalizations loc) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        key: const ValueKey('neighbourDirectorySwitch'),
        value: _showInNeighbourDirectory,
        secondary: const Icon(Icons.holiday_village_outlined),
        title: Text(loc.memberProfileNeighbourDirectoryLabel),
        subtitle: Text(loc.memberProfileNeighbourDirectoryHint),
        onChanged: (v) {
          setState(() => _showInNeighbourDirectory = v);
          _syncDraft(context);
        },
      ),
    );
  }

  Widget _fieldsCard(String title, List<String> keys, AppLocalizations loc) {
    return AppCard(title: title, child: FieldGrid(children: [for (final k in keys) _field(k, loc)]));
  }

  Widget _addressCard(AppLocalizations loc) {
    final theme = Theme.of(context);
    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
        );
    return AppCard(
      title: loc.memberProfileAddressTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label(loc.memberProfilePermanentAddressLabel),
          FieldGrid(children: [for (final k in _permanentKeys) _field(k, loc)]),
          const Divider(height: 32),
          label(loc.memberProfileCurrentAddressLabel),
          FieldGrid(children: [for (final k in _currentKeys) _field(k, loc)]),
        ],
      ),
    );
  }

  Widget _field(String key, AppLocalizations loc) {
    final isLast = key == _contactKeys.last;
    return TextField(
      controller: _controllers[key],
      keyboardType: _keyboardFor(key),
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      textCapitalization: key == 'email' ? TextCapitalization.none : TextCapitalization.words,
      autocorrect: key != 'email',
      onChanged: (_) => _syncDraft(context),
      decoration: InputDecoration(
        labelText: _labelFor(key, loc),
        prefixIcon: Icon(_iconFor(key)),
      ),
    );
  }

  TextInputType _keyboardFor(String key) => switch (key) {
        'mobile' || 'urgentContactMobile' => TextInputType.phone,
        'email' => TextInputType.emailAddress,
        'nid' => TextInputType.number,
        'dob' => TextInputType.datetime,
        'fullName' || 'fatherOrHusband' || 'mother' || 'urgentContactName' => TextInputType.name,
        _ => TextInputType.text,
      };

  IconData _iconFor(String key) => switch (key) {
        'fullName' => Icons.person_outline,
        'fatherOrHusband' || 'mother' => Icons.family_restroom_outlined,
        'dob' => Icons.cake_outlined,
        'nationality' => Icons.flag_outlined,
        'occupation' => Icons.work_outline,
        'nid' => Icons.badge_outlined,
        'gender' => Icons.wc_outlined,
        'mobile' => Icons.phone_outlined,
        'email' => Icons.email_outlined,
        'urgentContactName' => Icons.contact_emergency_outlined,
        'urgentContactRelation' => Icons.people_outline,
        'urgentContactMobile' => Icons.phone_in_talk_outlined,
        'permanentHouse' || 'currentHouse' || 'urgentContactAddress' => Icons.home_outlined,
        'permanentRoad' || 'currentRoad' => Icons.signpost_outlined,
        'permanentPostOffice' || 'currentPostOffice' => Icons.local_post_office_outlined,
        _ => Icons.location_city_outlined,
      };

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

/// Sticky cancel / save bar so the primary action is always reachable.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.onCancel, required this.onSave});

  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: Breakpoints.formMaxWidth,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.pageGutter, vertical: 12),
            child: BlocBuilder<ProfileBloc, ProfileState>(
              buildWhen: (a, b) => a.saving != b.saving,
              builder: (context, state) => Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: loc.memberProfileCancelButton,
                      variant: AppButtonVariant.secondary,
                      onPressed: state.saving ? null : onCancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: state.saving ? loc.commonLoading : loc.memberProfileSaveButton,
                      icon: Icons.save_outlined,
                      loading: state.saving,
                      onPressed: onSave,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
