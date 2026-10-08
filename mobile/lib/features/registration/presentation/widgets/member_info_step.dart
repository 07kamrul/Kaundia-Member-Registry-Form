import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/geo_repository.dart';
import '../../domain/registration_form.dart';
import '../../domain/registration_validators.dart';
import '../bloc/registration_bloc.dart';
import 'registration_inputs.dart';
import 'registration_l10n.dart';

/// Step 1: member photo + personal fields (member-info.component) and both
/// address blocks with cascading বিভাগ/জেলা/উপজেলা dropdowns
/// (address-info.component).
class MemberInfoStep extends StatelessWidget {
  const MemberInfoStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegSectionTitle(text: l10n.registrationStepTitlesMemberInfo),
        const RegSectionCard(child: _PersonalFields()),
        const SizedBox(height: 16),
        const _AddressBlocks(),
      ],
    );
  }
}

class _PersonalFields extends StatelessWidget {
  const _PersonalFields();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final f = state.form;

    String? err(RegErrorKind kind) {
      final e = findError(state.stepErrors, kind);
      return e == null ? null : regErrorMessage(l10n, e);
    }

    void change(MemberField field, String v) => bloc.add(MemberFieldChanged(field, v));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MemberPhotoField(),
        const SizedBox(height: 16),
        RegTextField(
          label: l10n.registrationMemberInfoFullNameLabel,
          required: true,
          value: f.fullName,
          prefixIcon: Icons.person_outline,
          autofillHints: const [AutofillHints.name],
          textCapitalization: TextCapitalization.words,
          error: err(RegErrorKind.fullNameRequired),
          onChanged: (v) => change(MemberField.fullName, v),
        ),
        const SizedBox(height: 12),
        RegFieldPair(
          first: RegTextField(
            label: l10n.registrationMemberInfoFatherOrHusbandLabel,
            required: true,
            value: f.fatherOrHusband,
            textCapitalization: TextCapitalization.words,
            error: err(RegErrorKind.fatherOrHusbandRequired),
            onChanged: (v) => change(MemberField.fatherOrHusband, v),
          ),
          second: RegTextField(
            label: l10n.registrationMemberInfoMotherLabel,
            required: true,
            value: f.mother,
            textCapitalization: TextCapitalization.words,
            error: err(RegErrorKind.motherRequired),
            onChanged: (v) => change(MemberField.mother, v),
          ),
        ),
        const SizedBox(height: 12),
        RegFieldPair(
          first: const _DobField(),
          second: RegTextField(
            label: l10n.registrationMemberInfoNidLabel,
            required: true,
            value: f.nid,
            hint: l10n.registrationMemberInfoNidPlaceholder,
            prefixIcon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            error: err(RegErrorKind.nidInvalid),
            onChanged: (v) => change(MemberField.nid, v),
          ),
        ),
        const SizedBox(height: 12),
        RegFieldPair(
          first: RegTextField(
            label: l10n.registrationMemberInfoMobileLabel,
            required: true,
            value: f.mobile,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            error: err(RegErrorKind.mobileRequired) ?? err(RegErrorKind.mobileInvalid),
            hint: '+8801XXXXXXXXX',
            onChanged: (v) => change(MemberField.mobile, v),
          ),
          second: RegTextField(
            label: l10n.registrationMemberInfoEmailLabel,
            required: true,
            value: f.email,
            prefixIcon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            error: err(RegErrorKind.emailInvalid),
            onChanged: (v) => change(MemberField.email, v),
          ),
        ),
        const SizedBox(height: 12),
        RegFieldPair(
          first: RegTextField(
            label: l10n.registrationMemberInfoOccupationLabel,
            value: f.occupation,
            prefixIcon: Icons.work_outline,
            onChanged: (v) => change(MemberField.occupation, v),
          ),
          second: RegTextField(
            label: l10n.registrationMemberInfoNationalityLabel,
            value: f.nationality,
            prefixIcon: Icons.flag_outlined,
            onChanged: (v) => change(MemberField.nationality, v),
          ),
        ),
        const SizedBox(height: 12),
        const _GenderField(),
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
    final theme = Theme.of(context);
    final bloc = context.read<RegistrationBloc>();
    final photoError = findError(state.stepErrors, RegErrorKind.photoRequired) != null;
    final hasPhoto = state.form.memberPhoto?.hasFile ?? false;

    return Center(
      child: Column(
        children: [
          Semantics(
            button: true,
            label: l10n.registrationMemberInfoPhotoAlt,
            child: InkWell(
              onTap: () => _showSourceSheet(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: photoError ? theme.colorScheme.error : theme.colorScheme.outline,
                    width: photoError ? 2 : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: hasPhoto
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md - 1),
                        child: Image.file(
                          File(state.form.memberPhoto!.path!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(context, l10n),
                        ),
                      )
                    : _placeholder(context, l10n),
              ),
            ),
          ),
          if (hasPhoto)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => bloc.add(MemberPhotoCleared()),
              label: Text(l10n.registrationMemberInfoClearPhotoButton),
            ),
          if (photoError)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.registrationMemberInfoMemberPhotoRequired,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(fontSize: 11);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 32, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            l10n.registrationMemberInfoPhotoPlaceholder,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
        ),
        Text('2"×2"', style: muted),
      ],
    );
  }

  void _showSourceSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        void pick(ImageSource source) {
          Navigator.of(sheetContext).pop();
          _pick(context, source);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.registrationMemberInfoPhotoAlt),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => pick(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.registrationMemberInfoPhotoAlt),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => pick(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegLabel(required: true, text: l10n.registrationMemberInfoDobLabel),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(f.dob) ?? DateTime(1990),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              initialEntryMode: DatePickerEntryMode.calendarOnly,
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
              prefixIcon: const Icon(Icons.cake_outlined, size: 20),
              suffixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
              errorText: error ? l10n.registrationValidationDobRequired : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            child: Text(
              f.dob.isEmpty ? 'YYYY-MM-DD' : f.dob,
              style: f.dob.isEmpty
                  ? theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                  : theme.textTheme.bodyLarge,
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
          : const SkeletonLoader(lines: 2, height: 120);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegSectionTitle(text: l10n.registrationStepTitlesAddressInfo),
        const RegFieldPair(
          minWidth: 600,
          first: _AddressBlock(isCurrent: true),
          second: _AddressBlock(isCurrent: false),
        ),
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

    return RegSectionCard(
      title: isCurrent
          ? l10n.registrationAddressInfoCurrentAddressTitle
          : l10n.registrationAddressInfoPermanentAddressTitle,
      icon: isCurrent ? Icons.home_outlined : Icons.location_city_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isCurrent) ...[
            RegCheckboxRow(
              value: state.form.sameAsCurrentAddress,
              label: l10n.registrationAddressInfoSameAsCurrentLabel,
              onChanged: (v) => bloc.add(SameAsCurrentToggled(v)),
            ),
            const SizedBox(height: 8),
          ],
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
            autofillHints: isCurrent ? const [AutofillHints.streetAddressLine1] : null,
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
