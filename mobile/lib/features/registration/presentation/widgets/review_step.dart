import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/registration_form.dart';
import '../../../../core/enums/enums.dart';
import '../bloc/registration_bloc.dart';
import 'registration_inputs.dart';

/// Step 6: read-only summary of every section with per-section edit buttons
/// (review-summary.component).
class ReviewStep extends StatelessWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final l10n = AppLocalizations.of(context);
    final f = state.form;

    List<(String, String)> addressRows(bool current) {
      final a = current ? f.currentAddress : f.permanentAddress;
      return <(String, String)>[
        (l10n.registrationAddressInfoDivisionLabel, a.division),
        (l10n.registrationAddressInfoDistrictLabel, a.district),
        (l10n.registrationAddressInfoUpazilaLabel, a.upazila),
        (l10n.registrationAddressInfoPostOfficeLabel, a.postOffice),
        (l10n.registrationAddressInfoRoadLabel, a.road),
        (l10n.registrationAddressInfoHouseLabel, a.house),
      ];
    }

    final gender = switch (f.gender) {
      Gender.male => l10n.registrationMemberInfoGenderMale,
      Gender.female => l10n.registrationMemberInfoGenderFemale,
      _ => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegSectionTitle(text: l10n.registrationReviewIntro),
        _ReviewSection(
          title: l10n.registrationReviewMemberInfoTitle,
          icon: Icons.person_outline,
          step: 1,
          rows: [
            (l10n.registrationReviewNameLabel, f.fullName),
            (l10n.registrationReviewFatherOrHusbandLabel, f.fatherOrHusband),
            (l10n.registrationMemberInfoMotherLabel, f.mother),
            (l10n.registrationMemberInfoDobLabel, f.dob),
            (l10n.registrationMemberInfoNationalityLabel, f.nationality),
            (l10n.registrationMemberInfoOccupationLabel, f.occupation),
            (l10n.registrationMemberInfoNidLabel, f.nid),
            (l10n.registrationReviewMobileLabel, f.mobile),
            (l10n.registrationMemberInfoGenderLabel, gender),
            (l10n.registrationMemberInfoEmailLabel, f.email),
          ],
        ),
        _ReviewSection(
          title: l10n.registrationAddressInfoCurrentAddressTitle,
          icon: Icons.home_outlined,
          step: 1,
          rows: addressRows(true),
        ),
        _ReviewSection(
          title: l10n.registrationAddressInfoPermanentAddressTitle,
          icon: Icons.location_city_outlined,
          step: 1,
          rows: addressRows(false),
        ),
        _ReviewSection(
          title: l10n.registrationReviewPropertyInfoTitle,
          icon: Icons.home_work_outlined,
          step: 2,
          rows: [
            (l10n.registrationPropertyCountLabel, f.propertyCount?.toString() ?? ''),
            (l10n.registrationReviewTotalPropertiesSummary(f.properties.length), ''),
            for (var i = 0; i < f.properties.length; i++)
              (
                '${l10n.registrationPropertyItemTitle} #${i + 1}',
                _propertySummary(f.properties[i]),
              ),
          ],
        ),
        _ReviewSection(
          title: l10n.registrationReviewUrgentContactAndNomineeTitle,
          icon: Icons.contact_phone_outlined,
          step: 3,
          rows: [
            (l10n.registrationReviewUrgentContactLabel, f.urgentContactName),
            (l10n.registrationUrgentContactMobileLabel, f.urgentContactMobile),
            (l10n.registrationReviewNomineeCountSummary(f.nominees.length), ''),
            for (final n in f.nominees) (l10n.registrationNomineeNameLabel, n.name),
          ],
        ),
        _ReviewSection(
          title: l10n.registrationReviewPaymentInfoTitle,
          icon: Icons.payments_outlined,
          step: 4,
          rows: [
            (l10n.registrationPaymentReceiptNoLabel, f.receiptNo),
            (l10n.registrationReviewMethodLabel, f.paymentMethod.apiValue),
          ],
        ),
        _ReviewSection(
          title: l10n.registrationReviewDeclarationTitle,
          icon: Icons.gavel_outlined,
          step: 5,
          rows: [
            (
              l10n.registrationReviewDeclarationAccepted,
              f.declarationAccepted ? '✓' : l10n.registrationReviewDeclarationNotAccepted
            ),
          ],
        ),
      ],
    );
  }

  String _propertySummary(PropertyItem p) => [
        p.propertyType.join(', '),
        p.khatianNo,
        'CS ${p.dagNoCs} / RS ${p.dagNoRs}',
        p.landQuantity,
        p.myShareQuantity,
        p.ownership == OwnershipType.joint ? 'যৌথ' : 'একক',
      ].where((s) => s.isNotEmpty).join(' · ');
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.icon,
    required this.step,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final int step;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<RegistrationBloc>();
    return RegSectionCard(
      title: title,
      icon: icon,
      // Icon-only on phones so long section titles keep their room.
      trailing: context.isCompact
          ? IconButton(
              tooltip: l10n.registrationReviewEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => bloc.add(StepGoToRequested(step)),
            )
          : TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              onPressed: () => bloc.add(StepGoToRequested(step)),
              label: Text(l10n.registrationReviewEdit),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (label, value) in rows)
            if (value.isNotEmpty) DetailRow(label: label, value: value),
        ],
      ),
    );
  }
}
