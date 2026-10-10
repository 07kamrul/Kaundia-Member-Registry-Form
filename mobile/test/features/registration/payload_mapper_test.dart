import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/enums/enums.dart';
import 'package:kaundia_app/features/registration/domain/registration_form.dart';
import 'package:kaundia_app/features/registration/domain/registration_payload_mapper.dart';

/// Asserts EVERY snake_case field of the POST /submissions payload, mirroring
/// Angular registration.service.ts (a past bug: raw snake_case typed as
/// camelCase).
void main() {
  final form = RegistrationForm(
    fullName: 'Md Kamrul Hasan',
    fatherOrHusband: 'Abdul Karim',
    mother: 'Rahima Begum',
    dob: '1990-01-02',
    nationality: 'বাংলাদেশী',
    occupation: 'কৃষক',
    nid: '1234567890',
    mobile: '+8801712345678',
    gender: Gender.male,
    email: 'kamrul@example.com',
    permanentAddress: const AddressDetail(
      house: '১',
      road: '২',
      postOffice: 'ক',
      upazila: 'খ',
      district: 'গ',
      division: 'ঘ',
    ),
    currentAddress: const AddressDetail(
      house: '৫',
      road: '৬',
      postOffice: 'চ',
      upazila: 'ছ',
      district: 'জ',
      division: 'ঝ',
    ),
    urgentContactName: 'Urgent Uddin',
    urgentContactRelation: 'ভাই',
    urgentContactMobile: '+8801812345678',
    urgentContactAddress: 'কুমিল্লা',
    propertyCount: 2,
    properties: [
      const PropertyItem(
        propertyType: ['জমি'],
        propertyTypeOther: '',
        khatianNo: 'KH-1',
        dagNoCs: 'CS-1',
        dagNoRs: 'RS-1',
        holdingNumber: 'H-1',
        landQuantity: '10',
        myShareQuantity: '5',
        ownership: OwnershipType.single,
        applicableDocs: [ApplicableDoc(type: 'খতিয়ান/পর্চা')],
      ),
      const PropertyItem(
        propertyType: ['বাড়ি'],
        propertyTypeOther: 'দোকানসহ',
        khatianNo: 'KH-2',
        dagNoCs: 'CS-2',
        dagNoRs: 'RS-2',
        holdingNumber: 'H-2',
        landQuantity: '8',
        myShareQuantity: '4',
        ownership: OwnershipType.joint,
        jointOwnerCount: 3,
        applicableDocs: [ApplicableDoc(type: 'নামজারি/মিউটেশন')],
      ),
    ],
    nominees: [
      const Nominee(
          name: 'Nominee One',
          relation: 'স্ত্রী',
          mobile: '+8801912345678',
          address: 'ঢাকা'),
      const Nominee(
          name: 'Nominee Two',
          relation: 'ছেলে',
          mobile: '+8801612345678',
          address: 'গাজীপুর'),
    ],
    receiptNo: 'RCPT-9',
    paymentMethod: PaymentMethod.bank,
    submissionDate: '2026-10-08',
  );

  test('payload carries every snake_case field with correct spelling', () {
    final p = buildRegistrationPayload(form,
        admissionFee: '500', subscription: '120');

    expect(p['full_name'], 'Md Kamrul Hasan');
    expect(p['father_or_husband'], 'Abdul Karim');
    expect(p['mother'], 'Rahima Begum');
    expect(p['dob'], '1990-01-02');
    expect(p['nationality'], 'বাংলাদেশী');
    expect(p['occupation'], 'কৃষক');
    expect(p['nid'], '1234567890');
    expect(p['mobile'], '+8801712345678');
    expect(p['gender'], 'পুরুষ');
    expect(p['email'], 'kamrul@example.com');

    // Address blocks: permanent_address / current_address with post_office.
    expect(p['permanent_address'], {
      'house': '১',
      'road': '২',
      'post_office': 'ক',
      'upazila': 'খ',
      'district': 'গ',
      'division': 'ঘ',
    });
    expect(p['current_address'], {
      'house': '৫',
      'road': '৬',
      'post_office': 'চ',
      'upazila': 'ছ',
      'district': 'জ',
      'division': 'ঝ',
    });

    expect(p['urgent_contact_name'], 'Urgent Uddin');
    expect(p['urgent_contact_relation'], 'ভাই');
    expect(p['urgent_contact_mobile'], '+8801812345678');
    expect(p['urgent_contact_address'], 'কুমিল্লা');

    expect(p['admission_fee'], '500');
    expect(p['subscription'], '120');
    expect(p['receipt_no'], 'RCPT-9');
    expect(p['payment_method'], 'ব্যাংক');
    expect(p['submission_date'], '2026-10-08');

    // Properties: dag_no_cs/dag_no_rs; joint_owner_count only when যৌথ.
    final props = p['properties'] as List;
    expect(props.length, 2);
    final single = props[0] as Map;
    expect(single['property_type'], ['জমি']);
    expect(single['property_type_other'], '');
    expect(single['khatian_no'], 'KH-1');
    expect(single['dag_no_cs'], 'CS-1');
    expect(single['dag_no_rs'], 'RS-1');
    expect(single['holding_number'], 'H-1');
    expect(single['land_quantity'], '10');
    expect(single['my_share_quantity'], '5');
    expect(single['ownership'], 'একক');
    expect(single['joint_owner_count'], isNull);
    expect((single['applicable_docs'] as List).single,
        {'doc_type': 'খতিয়ান/পর্চা'});

    final joint = props[1] as Map;
    expect(joint['ownership'], 'যৌথ');
    expect(joint['joint_owner_count'], 3);
    expect(joint['property_type_other'], 'দোকানসহ');

    // Nominees verbatim.
    final nominees = p['nominees'] as List;
    expect(nominees, [
      {
        'name': 'Nominee One',
        'relation': 'স্ত্রী',
        'mobile': '+8801912345678',
        'address': 'ঢাকা'
      },
      {
        'name': 'Nominee Two',
        'relation': 'ছেলে',
        'mobile': '+8801612345678',
        'address': 'গাজীপুর'
      },
    ]);
  });

  test('joint_owner_count is null for single ownership even when count set',
      () {
    final p = buildRegistrationPayload(
      form.copyWith(
        properties: [
          form.properties.first.copyWith(
            ownership: OwnershipType.single,
            jointOwnerCount: 7,
          ),
        ],
      ),
      admissionFee: '500',
      subscription: '120',
    );
    expect((p['properties'] as List).single['joint_owner_count'], isNull);
  });
}
