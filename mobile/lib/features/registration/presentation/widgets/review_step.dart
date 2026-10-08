import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/registration_form.dart';
import '../../../../core/enums/enums.dart';
import '../bloc/registration_bloc.dart';
import '../bloc/registration_event.dart';
import 'registration_inputs.dart';

/// Step 6: read-only summary of every section with per-section edit buttons
/// (review-summary.component).
class ReviewStep extends StatelessWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationBloc>().state;
    final bloc = context.read<RegistrationBloc>();
    final l10n = AppLocalizations.of(context);
    final f = state.form;

    Widget buildSection({required String title, required int step, required List<(String, String)> rows}) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
                TextButton(
                  onPressed: () => bloc.add(StepGoToRequested(step)),
                  child: Text(l10n.registrationReviewEdit),
                ),
              ],
            ),
            for (final (label, value) in rows)
              if (value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: value),
                    ]),
                  ),
                ),
          ],
        ),
      );
    }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegSectionTitle(text: l10n.registrationReviewIntro),
        buildSection(
          title: l10n.registrationReviewMemberInfoTitle,
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
            (l10n.registrationMemberInfoGenderLabel, f.gender == Gender.male ? l10n.registrationMemberInfoGenderMale : (f.gender == Gender.female ? l10n.registrationMemberInfoGenderFemale : '')),
            (l10n.registrationMemberInfoEmailLabel, f.email),
          ],
        ),
        buildSection(
          title: l10n.registrationAddressInfoCurrentAddressTitle,
          step: 1,
          rows: addressRows(true),
        ),
        buildSection(
          title: l10n.registrationAddressInfoPermanentAddressTitle,
          step: 1,
          rows: addressRows(false),
        ),
        buildSection(
          title: l10n.registrationReviewPropertyInfoTitle,
          step: 2,
          rows: [
            (l10n.registrationPropertyCountLabel, f.propertyCount?.toString() ?? ''),
            (l10n.registrationReviewTotalPropertiesSummary(f.properties.length), ''),
            for (var i = 0; i < f.properties.length; i++)
              (
                '${l10n.registrationPropertyItemTitle} #${i + 1}',
                [
                  f.properties[i].propertyType.join(', '),
                  f.properties[i].khatianNo,
                  'CS ${f.properties[i].dagNoCs} / RS ${f.properties[i].dagNoRs}',
                  f.properties[i].landQuantity,
                  f.properties[i].myShareQuantity,
                  f.properties[i].ownership == OwnershipType.joint ? 'যৌথ' : 'একক',
                ].where((s) => s.isNotEmpty).join(' · ')
              ),
          ],
        ),
        buildSection(
          title: l10n.registrationReviewUrgentContactAndNomineeTitle,
          step: 3,
          rows: [
            (l10n.registrationReviewUrgentContactLabel, f.urgentContactName),
            (l10n.registrationUrgentContactMobileLabel, f.urgentContactMobile),
            (l10n.registrationReviewNomineeCountSummary(f.nominees.length), ''),
            for (final n in f.nominees) (l10n.registrationNomineeNameLabel, n.name),
          ],
        ),
        buildSection(
          title: l10n.registrationReviewPaymentInfoTitle,
          step: 4,
          rows: [
            (l10n.registrationPaymentReceiptNoLabel, f.receiptNo),
            (l10n.registrationReviewMethodLabel, f.paymentMethod.apiValue),
          ],
        ),
        buildSection(
          title: l10n.registrationReviewDeclarationTitle,
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
}
