import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/registration_validators.dart';
import '../bloc/registration_bloc.dart';
import '../bloc/registration_event.dart';
import 'registration_inputs.dart';
import 'registration_l10n.dart';

/// Step 3: urgent contact (urgent-contact.component) + repeatable nominee list
/// (nominee-list.component, max 5, first nominee "same as urgent contact").
class ContactStep extends StatelessWidget {
  const ContactStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final f = state.form;

    String? urgentErr(RegErrorKind kind) {
      final e = findError(state.stepErrors, kind);
      return e == null ? null : regErrorMessage(l10n, e);
    }

    final urgentCard = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RegSectionTitle(text: l10n.registrationStepTitlesUrgentContact),
          RegTextField(
            label: l10n.registrationUrgentContactNameLabel,
            required: true,
            value: f.urgentContactName,
            error: urgentErr(RegErrorKind.urgentNameRequired),
            onChanged: (v) => bloc.add(UrgentContactFieldChanged(UrgentField.name, v)),
          ),
          const SizedBox(height: 12),
          RegTextField(
            label: l10n.registrationUrgentContactRelationLabel,
            value: f.urgentContactRelation,
            onChanged: (v) => bloc.add(UrgentContactFieldChanged(UrgentField.relation, v)),
          ),
          const SizedBox(height: 12),
          RegTextField(
            label: l10n.registrationUrgentContactMobileLabel,
            required: true,
            value: f.urgentContactMobile,
            keyboardType: TextInputType.phone,
            hint: '+8801XXXXXXXXX',
            error: urgentErr(RegErrorKind.urgentMobileRequired) ?? urgentErr(RegErrorKind.urgentMobileInvalid),
            onChanged: (v) => bloc.add(UrgentContactFieldChanged(UrgentField.mobile, v)),
          ),
          const SizedBox(height: 12),
          RegTextField(
            label: l10n.registrationUrgentContactAddressLabel,
            value: f.urgentContactAddress,
            onChanged: (v) => bloc.add(UrgentContactFieldChanged(UrgentField.address, v)),
          ),
        ],
      ),
    );

    final nomineeCards = <Widget>[
      for (var i = 0; i < f.nominees.length; i++) _NomineeCard(index: i),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        urgentCard,
        const SizedBox(height: 16),
        RegSectionTitle(text: l10n.registrationStepTitlesNominee),
        if (f.nominees.isNotEmpty)
          RegCheckboxRow(
            value: false,
            label: l10n.registrationNomineeSameAsUrgentContactLabel,
            onChanged: (v) => bloc.add(SameAsUrgentToggled(v)),
          ),
        ...nomineeCards,
        if (f.nominees.length < 5)
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(l10n.registrationNomineeAddMore),
            onPressed: () => bloc.add(NomineeAdded()),
          ),
      ],
    );
  }
}

class _NomineeCard extends StatelessWidget {
  const _NomineeCard({required this.index});

  final int index;

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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.registrationNomineeNomineeNumberTitle(index + 1),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (index > 0)
                TextButton(
                  onPressed: () => bloc.add(NomineeRemoved(index)),
                  child: Text(l10n.registrationNomineeRemove),
                ),
            ],
          ),
          RegTextField(
            label: l10n.registrationNomineeNameLabel,
            required: true,
            value: n.name,
            error: err(RegErrorKind.nomineeNameRequired),
            onChanged: (v) => bloc.add(NomineeFieldChanged(index, NomineeField.name, v)),
          ),
          const SizedBox(height: 12),
          RegTextField(
            label: l10n.registrationNomineeRelationLabel,
            value: n.relation,
            onChanged: (v) => bloc.add(NomineeFieldChanged(index, NomineeField.relation, v)),
          ),
          const SizedBox(height: 12),
          RegTextField(
            label: l10n.registrationNomineeMobileLabel,
            required: true,
            value: n.mobile,
            keyboardType: TextInputType.phone,
            hint: '+8801XXXXXXXXX',
            error: err(RegErrorKind.nomineeMobileRequired) ?? err(RegErrorKind.nomineeMobileInvalid),
            onChanged: (v) => bloc.add(NomineeFieldChanged(index, NomineeField.mobile, v)),
          ),
          const SizedBox(height: 12),
          RegTextField(
            label: l10n.registrationNomineeAddressLabel,
            value: n.address,
            onChanged: (v) => bloc.add(NomineeFieldChanged(index, NomineeField.address, v)),
          ),
        ],
      ),
    );
  }
}
