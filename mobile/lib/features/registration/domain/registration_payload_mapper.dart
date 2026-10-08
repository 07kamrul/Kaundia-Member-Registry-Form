import '../../../core/enums/enums.dart';
import 'registration_form.dart';

/// Builds the JSON `payload` form field for POST /submissions, mirroring
/// Angular registration.service.ts submit() exactly (snake_case keys,
/// joint_owner_count only present as a number when ownership is 'যৌথ',
/// applicable_docs as [{doc_type}], nominees verbatim).
///
/// Fee-derived amounts are supplied by the caller from the live fee settings /
/// subscription quote — they are never stored on the form.
Map<String, dynamic> buildRegistrationPayload(
  RegistrationForm form, {
  required String admissionFee,
  required String subscription,
}) {
  Map<String, dynamic>? addressToJson(AddressDetail a) => {
        'house': a.house,
        'road': a.road,
        'post_office': a.postOffice,
        'upazila': a.upazila,
        'district': a.district,
        'division': a.division,
      };

  return {
    'full_name': form.fullName,
    'father_or_husband': form.fatherOrHusband,
    'mother': form.mother,
    'dob': form.dob,
    'nationality': form.nationality,
    'occupation': form.occupation,
    'nid': form.nid,
    'mobile': form.mobile,
    'gender': form.gender.apiValue,
    'email': form.email,
    'permanent_address': addressToJson(form.permanentAddress),
    'current_address': addressToJson(form.currentAddress),
    'urgent_contact_name': form.urgentContactName,
    'urgent_contact_relation': form.urgentContactRelation,
    'urgent_contact_mobile': form.urgentContactMobile,
    'urgent_contact_address': form.urgentContactAddress,
    'admission_fee': admissionFee,
    'subscription': subscription,
    'receipt_no': form.receiptNo,
    'payment_method': form.paymentMethod.apiValue,
    'member_signature': form.memberSignature,
    'submission_date': form.submissionDate,
    'properties': [
      for (final p in form.properties)
        {
          'property_type': p.propertyType,
          'property_type_other': p.propertyTypeOther,
          'khatian_no': p.khatianNo,
          'dag_no_cs': p.dagNoCs,
          'dag_no_rs': p.dagNoRs,
          'holding_number': p.holdingNumber,
          'land_quantity': p.landQuantity,
          'my_share_quantity': p.myShareQuantity,
          'ownership': p.ownership == OwnershipType.joint
              ? OwnershipTypeX.jointSentinel
              : 'একক',
          'joint_owner_count': p.isJoint ? p.jointOwnerCount : null,
          'applicable_docs': [
            for (final doc in p.applicableDocs) {'doc_type': doc.type},
          ],
        },
    ],
    'nominees': [
      for (final n in form.nominees)
        {'name': n.name, 'relation': n.relation, 'mobile': n.mobile, 'address': n.address},
    ],
  };
}
