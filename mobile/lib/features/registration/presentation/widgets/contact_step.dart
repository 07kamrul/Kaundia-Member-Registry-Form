import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/registration_validators.dart';
import '../bloc/registration_bloc.dart';
import 'registration_inputs.dart';
import 'registration_l10n.dart';

/// Step 3: urgent contact (urgent-contact.component) + repeatable nominee list
/// (nominee-list.component, max 5, first nominee "same as urgent contact").
class ContactStep extends StatelessWidget {
  const ContactStep({super.key});

  static const int _maxNominees = 5;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final f = state.form;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegSectionTitle(text: l10n.registrationStepTitlesUrgentContact),
        const _UrgentContactCard(),
        const SizedBox(height: 16),
        RegSectionTitle(text: l10n.registrationStepTitlesNominee),
        if (f.nominees.isNotEmpty)
          RegCheckboxRow(
            value: false,
            label: l10n.registrationNomineeSameAsUrgentContactLabel,
            onChanged: (v) => bloc.add(SameAsUrgentToggled(v)),
          ),
        for (var i = 0; i < f.nominees.length; i++) _NomineeCard(index: i),
        if (f.nominees.length < _maxNominees)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(l10n.registrationNomineeAddMore),
              onPressed: () => bloc.add(NomineeAdded()),
            ),
          ),
      ],
    );
  }
}

class _UrgentContactCard extends StatelessWidget {
  const _UrgentContactCard();

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

    void change(UrgentField field, String v) => bloc.add(UrgentContactFieldChanged(field, v));

    return RegSectionCard(
      child: _ContactFields(
        nameLabel: l10n.registrationUrgentContactNameLabel,
        relationLabel: l10n.registrationUrgentContactRelationLabel,
        mobileLabel: l10n.registrationUrgentContactMobileLabel,
        addressLabel: l10n.registrationUrgentContactAddressLabel,
        name: f.urgentContactName,
        relation: f.urgentContactRelation,
        mobile: f.urgentContactMobile,
        address: f.urgentContactAddress,
        nameError: err(RegErrorKind.urgentNameRequired),
        mobileError:
            err(RegErrorKind.urgentMobileRequired) ?? err(RegErrorKind.urgentMobileInvalid),
        onName: (v) => change(UrgentField.name, v),
        onRelation: (v) => change(UrgentField.relation, v),
        onMobile: (v) => change(UrgentField.mobile, v),
        onAddress: (v) => change(UrgentField.address, v),
      ),
    );
  }
}

class _NomineeCard extends StatelessWidget {
  const _NomineeCard({required this.index});

  final int index;

  Future<void> _confirmRemove(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegistrationBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.registrationNomineeRemove),
        content: Text(l10n.registrationNomineeNomineeNumberTitle(index + 1)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.registrationNomineeRemove),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(NomineeRemoved(index));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final n = state.form.nominees[index];

    String? err(RegErrorKind kind) {
      final e = findError(state.stepErrors, kind, nomineeIndex: index);
      return e == null ? null : regErrorMessage(l10n, e);
    }

    void change(NomineeField field, String v) => bloc.add(NomineeFieldChanged(index, field, v));

    return RegSectionCard(
      title: l10n.registrationNomineeNomineeNumberTitle(index + 1),
      icon: Icons.person_outline,
      trailing: index > 0
          ? IconButton(
              tooltip: l10n.registrationNomineeRemove,
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              onPressed: () => _confirmRemove(context),
            )
          : null,
      child: _ContactFields(
        nameLabel: l10n.registrationNomineeNameLabel,
        relationLabel: l10n.registrationNomineeRelationLabel,
        mobileLabel: l10n.registrationNomineeMobileLabel,
        addressLabel: l10n.registrationNomineeAddressLabel,
        name: n.name,
        relation: n.relation,
        mobile: n.mobile,
        address: n.address,
        nameError: err(RegErrorKind.nomineeNameRequired),
        mobileError:
            err(RegErrorKind.nomineeMobileRequired) ?? err(RegErrorKind.nomineeMobileInvalid),
        onName: (v) => change(NomineeField.name, v),
        onRelation: (v) => change(NomineeField.relation, v),
        onMobile: (v) => change(NomineeField.mobile, v),
        onAddress: (v) => change(NomineeField.address, v),
      ),
    );
  }
}

/// Name / relation / mobile / address group shared by the urgent contact and
/// nominee cards. Pairs fields side by side on wider screens.
class _ContactFields extends StatelessWidget {
  const _ContactFields({
    required this.nameLabel,
    required this.relationLabel,
    required this.mobileLabel,
    required this.addressLabel,
    required this.name,
    required this.relation,
    required this.mobile,
    required this.address,
    required this.nameError,
    required this.mobileError,
    required this.onName,
    required this.onRelation,
    required this.onMobile,
    required this.onAddress,
  });

  final String nameLabel;
  final String relationLabel;
  final String mobileLabel;
  final String addressLabel;
  final String name;
  final String relation;
  final String mobile;
  final String address;
  final String? nameError;
  final String? mobileError;
  final ValueChanged<String> onName;
  final ValueChanged<String> onRelation;
  final ValueChanged<String> onMobile;
  final ValueChanged<String> onAddress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegFieldPair(
          first: RegTextField(
            label: nameLabel,
            required: true,
            value: name,
            prefixIcon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            error: nameError,
            onChanged: onName,
          ),
          second: RegTextField(
            label: relationLabel,
            value: relation,
            prefixIcon: Icons.diversity_3_outlined,
            onChanged: onRelation,
          ),
        ),
        const SizedBox(height: 12),
        RegFieldPair(
          first: RegTextField(
            label: mobileLabel,
            required: true,
            value: mobile,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            hint: '+8801XXXXXXXXX',
            error: mobileError,
            onChanged: onMobile,
          ),
          second: RegTextField(
            label: addressLabel,
            value: address,
            prefixIcon: Icons.home_outlined,
            textInputAction: TextInputAction.done,
            onChanged: onAddress,
          ),
        ),
      ],
    );
  }
}
