import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/geo_repository.dart';
import '../../domain/registration_form.dart';
import '../../domain/registration_validators.dart';
import '../bloc/registration_bloc.dart';
import '../bloc/registration_event.dart';
import 'registration_inputs.dart';
import 'registration_l10n.dart';

/// Step 1: member photo + personal fields (member-info.component) and both
/// address blocks with cascading বিভাগ/জেলা/উপজেলা dropdowns
/// (address-info.component).
class MemberInfoStep extends StatelessWidget {
  const MemberInfoStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final f = state.form;
    final errs = state.stepErrors;

    String? err(RegErrorKind kind) {
      final e = findError(errs, kind);
      return e == null ? null : regErrorMessage(l10n, e);
    }

    final memberColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MemberPhotoField(),
        const SizedBox(height: 12),
        RegTextField(
          label: l10n.registrationMemberInfoFullNameLabel,
          required: true,
          value: f.fullName,
          error: err(RegErrorKind.fullNameRequired),
          onChanged: (v) => bloc.add(MemberFieldChanged(MemberField.fullName, v)),
        ),
        const SizedBox(height: 12),
        RegTextField(
          label: l10n.registrationMemberInfoFatherOrHusbandLabel,
          required: true,
          value: f.fatherOrHusband,
          error: err(RegErrorKind.fatherOrHusbandRequired),
          onChanged: (v) => bloc.add(MemberFieldChanged(MemberField.fatherOrHusband, v)),
        ),
        const SizedBox(height: 12),
        RegTextField(
          label: l10n.registrationMemberInfoMotherLabel,
          required: true,
          value: f.mother,
          error: err(RegErrorKind.motherRequired),
          onChanged: (v) => bloc.add(MemberFieldChanged(MemberField.mother, v)),
        ),
        const SizedBox(height: 12),
        const _DobField(),
      ],
    );

    final secondColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegTextField(
          label: l10n.registrationMemberInfoNidLabel,
          required: true,
          value: f.nid,
          hint: l10n.registrationMemberInfoNidPlaceholder,
          keyboardType: TextInputType.number,
          error: err(RegErrorKind.nidInvalid),
          onChanged: (v) => bloc.add(MemberFieldChanged(MemberField.nid, v)),
        ),
        const SizedBox(height: 12),
        RegTextField(
          label: l10n.registrationMemberInfoMobileLabel,
          required: true,
          value: f.mobile,
          keyboardType: TextInputType.phone,
          error: err(RegErrorKind.mobileRequired) ?? err(RegErrorKind.mobileInvalid),
          hint: '+8801XXXXXXXXX',
          onChanged: (v) => bloc.add(MemberFieldChanged(MemberField.mobile, v)),
        ),
        const SizedBox(height: 12),
        RegTextField(
          label: l10n.registrationMemberInfoEmailLabel,
          required: true,
          value: f.email,
          keyboardType: TextInputType.emailAddress,
          error: err(RegErrorKind.emailInvalid),
          onChanged: (v) => bloc.add(MemberFieldChanged(MemberField.email, v)),
        ),
        const SizedBox(height: 12),
        RegTextField(
          label: l10n.registrationMemberInfoOccupationLabel,
          value: f.occupation,
          onChanged: (v) => bloc.add(MemberFieldChanged(MemberField.occupation, v)),
        ),
        const SizedBox(height: 12),
        RegTextField(
          label: l10n.registrationMemberInfoNationalityLabel,
          value: f.nationality,
          onChanged: (v) => bloc.add(MemberFieldChanged(MemberField.nationality, v)),
        ),
        const SizedBox(height: 12),
        const _GenderField(),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegSectionTitle(text: l10n.registrationStepTitlesMemberInfo),
        LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: memberColumn),
                const SizedBox(width: 16),
                Expanded(child: secondColumn),
              ],
            );
          }
          return Column(children: [memberColumn, const SizedBox(height: 12), secondColumn]);
        }),
        const SizedBox(height: 16),
        const _AddressBlocks(),
      ],
    );
  }
}

/// 2"x2" photo slot with camera/gallery pick, preview and clear.
class _MemberPhotoField extends StatelessWidget {
  const _MemberPhotoField();

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final bloc = context.read<RegistrationBloc>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1200, maxHeight: 1200);
    if (picked == null) return;
    // Compression happens in the bloc (prepareImage).
    bloc.add(MemberPhotoAttached(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegistrationBloc>();
    final photoError = findError(state.stepErrors, RegErrorKind.photoRequired) != null;
    final hasPhoto = state.form.memberPhoto?.hasFile ?? false;

    return Center(
      child: Column(
        children: [
          InkWell(
            onTap: () => _showSourceSheet(context),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: photoError ? Theme.of(context).colorScheme.error : Theme.of(context).dividerColor,
                  width: photoError ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: hasPhoto
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.file(
                        File(state.form.memberPhoto!.path!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(l10n),
                      ),
                    )
                  : _placeholder(l10n),
            ),
          ),
          if (hasPhoto)
            TextButton(
              onPressed: () => bloc.add(MemberPhotoCleared()),
              child: Text(l10n.registrationMemberInfoClearPhotoButton),
            ),
          if (photoError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.registrationMemberInfoMemberPhotoRequired,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(AppLocalizations l10n) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_add_alt_1_outlined, size: 32),
          const SizedBox(height: 4),
          Text(l10n.registrationMemberInfoPhotoPlaceholder,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          const Text('2"×2"', style: TextStyle(fontSize: 11)),
        ],
      );

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(AppLocalizations.of(sheetContext).registrationMemberInfoPhotoAlt),
              onTap: () => _pick(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppLocalizations.of(sheetContext).registrationMemberInfoPhotoAlt),
              onTap: () => _pick(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

/// DOB picker row.
class _DobField extends StatelessWidget {
  const _DobField();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegistrationBloc>();
    final f = state.form;
    final error = findError(state.stepErrors, RegErrorKind.dobRequired) != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegLabel(required: true, text: l10n.registrationMemberInfoDobLabel),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(f.dob) ?? DateTime(1990),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              bloc.add(MemberFieldChanged(
                MemberField.dob,
                '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
              ));
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              errorText: error ? l10n.registrationValidationDobRequired : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(f.dob.isEmpty ? 'YYYY-MM-DD' : f.dob),
                const Icon(Icons.calendar_today, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderField extends StatelessWidget {
  const _GenderField();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegistrationBloc>();
    final error = findError(state.stepErrors, RegErrorKind.genderRequired);
    return RegLabel(
      required: true,
      text: l10n.registrationMemberInfoGenderLabel,
      error: error != null ? l10n.registrationValidationGenderRequired : null,
      child: Row(
        children: [
          Expanded(
            child: RegRadioRow<Gender>(
              value: Gender.male,
              groupValue: state.form.gender,
              label: l10n.registrationMemberInfoGenderMale,
              onChanged: (g) => bloc.add(MemberGenderSelected(g)),
            ),
          ),
          Expanded(
            child: RegRadioRow<Gender>(
              value: Gender.female,
              groupValue: state.form.gender,
              label: l10n.registrationMemberInfoGenderFemale,
              onChanged: (g) => bloc.add(MemberGenderSelected(g)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Both address blocks (current + permanent + "same as current" toggle) with
/// cascading geo dropdowns.
class _AddressBlocks extends StatelessWidget {
  const _AddressBlocks();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegistrationBloc>();
    final geo = state.geoData;

    if (geo == null) {
      return state.geoError
          ? InlineError(
              message: l10n.commonNetworkError,
              onRetry: () => bloc.add(const RegistrationStarted()),
            )
          : const SkeletonLoader(height: 120);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegSectionTitle(text: l10n.registrationStepTitlesAddressInfo),
        LayoutBuilder(builder: (context, constraints) {
          _AddressBlock block(bool isCurrent) => _AddressBlock(isCurrent: isCurrent);
          if (constraints.maxWidth >= 600) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: block(true)),
                const SizedBox(width: 16),
                Expanded(child: block(false)),
              ],
            );
          }
          return Column(children: [block(true), block(false)]);
        }),
      ],
    );
  }
}

class _AddressBlock extends StatelessWidget {
  const _AddressBlock({required this.isCurrent});

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegistrationBloc>();
    final geo = state.geoData!;
    final address = isCurrent ? state.form.currentAddress : state.form.permanentAddress;

    String? err(AddressField field) {
      final e = findError(
        state.stepErrors,
        RegErrorKind.addressFieldRequired,
        addressField: field,
        isCurrentAddress: isCurrent,
      );
      return e == null ? null : _fieldError(l10n, field);
    }

    void change(AddressField field, String value) =>
        bloc.add(AddressFieldChanged(isCurrent: isCurrent, field: field, value: value));

    final districts = geo.districtsByDivisionName(address.division);
    final upazilas = geo.upazilasByDistrictName(address.district);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrent)
            RegCheckboxRow(
              value: state.form.sameAsCurrentAddress,
              label: l10n.registrationAddressInfoSameAsCurrentLabel,
              onChanged: (v) => bloc.add(SameAsCurrentToggled(v)),
            ),
          Text(
            isCurrent
                ? l10n.registrationAddressInfoCurrentAddressTitle
                : l10n.registrationAddressInfoPermanentAddressTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          RegDropdown(
            label: l10n.registrationAddressInfoDivisionLabel,
            required: true,
            value: address.division,
            items: [for (final d in geo.divisions) d.bnName],
            error: err(AddressField.division),
            onChanged: (v) => change(AddressField.division, v ?? ''),
          ),
          const SizedBox(height: 12),
          RegDropdown(
            label: l10n.registrationAddressInfoDistrictLabel,
            required: true,
            value: address.district,
            items: [for (final d in districts) d.bnName],
            error: err(AddressField.district),
            onChanged: (v) => change(AddressField.district, v ?? ''),
          ),
          const SizedBox(height: 12),
          RegDropdown(
            label: l10n.registrationAddressInfoUpazilaLabel,
            required: true,
            value: address.upazila,
            items: [for (final u in upazilas) u.bnName],
            error: err(AddressField.upazila),
            onChanged: (v) => change(AddressField.upazila, v ?? ''),
          ),
          const SizedBox(height: 12),
          RegTextField(
            label: l10n.registrationAddressInfoPostOfficeLabel,
            required: true,
            value: address.postOffice,
            error: err(AddressField.postOffice),
            onChanged: (v) => change(AddressField.postOffice, v),
          ),
          const SizedBox(height: 12),
          RegTextField(
            label: l10n.registrationAddressInfoRoadLabel,
            required: true,
            value: address.road,
            error: err(AddressField.road),
            onChanged: (v) => change(AddressField.road, v),
          ),
          const SizedBox(height: 12),
          RegTextField(
            label: l10n.registrationAddressInfoHouseLabel,
            required: true,
            value: address.house,
            error: err(AddressField.house),
            onChanged: (v) => change(AddressField.house, v),
          ),
        ],
      ),
    );
  }

  String _fieldError(AppLocalizations l10n, AddressField field) => switch (field) {
        AddressField.division => l10n.registrationAddressInfoDivisionRequired,
        AddressField.district => l10n.registrationAddressInfoDistrictRequired,
        AddressField.upazila => l10n.registrationAddressInfoUpazilaRequired,
        AddressField.postOffice => l10n.registrationAddressInfoPostOfficeRequired,
        AddressField.road => l10n.registrationAddressInfoRoadRequired,
        AddressField.house => l10n.registrationAddressInfoHouseRequired,
      };
}
