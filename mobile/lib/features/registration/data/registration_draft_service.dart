import 'dart:convert';

import '../../../core/enums/enums.dart';
import '../../../core/storage/app_preferences.dart';
import '../domain/registration_form.dart';

/// Local draft persistence (Angular registration-draft.service.ts port).
/// schemaVersion 1 + currentStep + formValue JSON in
/// AppPreferences.registrationDraft.
///
/// Fee-derived values (admission fee, subscription) are NEVER written or
/// restored — a stale draft must not carry an outdated amount forward. File
/// attachments persist as metadata only (fileName); the bytes stay on the
//  device path which may vanish, so restore marks them missing and the UI
/// prompts re-attachment.
class RegistrationDraft {
  const RegistrationDraft({
    required this.schemaVersion,
    required this.currentStep,
    required this.lastSaved,
    required this.formValue,
  });

  final int schemaVersion;
  final int currentStep;
  final String lastSaved;
  final Map<String, dynamic> formValue;
}

const draftSchemaVersion = 1;

class RegistrationDraftService {
  RegistrationDraftService({required AppPreferences preferences}) : _preferences = preferences;

  final AppPreferences _preferences;

  /// Returns the saved draft, or null when absent or its schema is stale.
  RegistrationDraft? peekDraft() {
    final raw = _preferences.registrationDraft;
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final draft = RegistrationDraft(
        schemaVersion: (decoded['schemaVersion'] as num?)?.toInt() ?? -1,
        currentStep: (decoded['currentStep'] as num?)?.toInt() ?? 1,
        lastSaved: (decoded['lastSaved'] ?? '').toString(),
        formValue: Map<String, dynamic>.from(decoded['formValue'] as Map? ?? const {}),
      );
      if (draft.schemaVersion != draftSchemaVersion || draft.formValue.isEmpty) return null;
      return draft;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(RegistrationForm form, int currentStep) async {
    final draft = {
      'schemaVersion': draftSchemaVersion,
      'currentStep': currentStep,
      'lastSaved': DateTime.now().toUtc().toIso8601String(),
      'formValue': encodeForm(form),
    };
    await _preferences.setRegistrationDraft(jsonEncode(draft));
  }

  Future<void> clear() => _preferences.clearRegistrationDraft();

  Map<String, dynamic> encodeForm(RegistrationForm form) => {
        'fullName': form.fullName,
        'fatherOrHusband': form.fatherOrHusband,
        'mother': form.mother,
        'dob': form.dob,
        'nationality': form.nationality,
        'occupation': form.occupation,
        'nid': form.nid,
        'mobile': form.mobile,
        'gender': form.gender.name,
        'email': form.email,
        'permanentAddress': _addressJson(form.permanentAddress),
        'currentAddress': _addressJson(form.currentAddress),
        'sameAsCurrentAddress': form.sameAsCurrentAddress,
        'urgentContactName': form.urgentContactName,
        'urgentContactRelation': form.urgentContactRelation,
        'urgentContactMobile': form.urgentContactMobile,
        'urgentContactAddress': form.urgentContactAddress,
        'propertyCount': form.propertyCount,
        'properties': [
          for (final p in form.properties)
            {
              'propertyType': p.propertyType,
              'propertyTypeOther': p.propertyTypeOther,
              'khatianNo': p.khatianNo,
              'dagNoCs': p.dagNoCs,
              'dagNoRs': p.dagNoRs,
              'holdingNumber': p.holdingNumber,
              'landQuantity': p.landQuantity,
              'myShareQuantity': p.myShareQuantity,
              'ownership': p.ownership.name,
              'jointOwnerCount': p.jointOwnerCount,
              'applicableDocs': [
                // Metadata only — file paths are intentionally dropped.
                for (final doc in p.applicableDocs)
                  {'type': doc.type, 'fileName': doc.fileName, 'fileMissing': !doc.hasFile || doc.fileName.isEmpty},
              ],
            },
        ],
        'nominees': [
          for (final n in form.nominees)
            {'name': n.name, 'relation': n.relation, 'mobile': n.mobile, 'address': n.address},
        ],
        'receiptNo': form.receiptNo,
        'paymentMethod': form.paymentMethod.name,
        'receiptFile': form.receiptFile == null ? null : {'fileName': form.receiptFile!.fileName},
        'memberPhoto': form.memberPhoto == null ? null : {'fileName': form.memberPhoto!.fileName},
        'memberSignature': '',
        'submissionDate': form.submissionDate,
        'declarationAccepted': form.declarationAccepted,
      };

  RegistrationForm decodeForm(Map<String, dynamic> value) {
    FileRef? fileRefJson(dynamic raw) {
      if (raw is Map && raw['fileName'] != null) {
        // Metadata restored; path intentionally null (bytes never persisted).
        return FileRef(fileName: raw['fileName'].toString());
      }
      return null;
    }

    AddressDetail addressJson(dynamic raw) {
      if (raw is! Map) return const AddressDetail();
      return AddressDetail(
        house: (raw['house'] ?? '').toString(),
        road: (raw['road'] ?? '').toString(),
        postOffice: (raw['postOffice'] ?? '').toString(),
        upazila: (raw['upazila'] ?? '').toString(),
        district: (raw['district'] ?? '').toString(),
        division: (raw['division'] ?? '').toString(),
      );
    }

    final properties = <PropertyItem>[
      if (value['properties'] is List)
        for (final rawP in value['properties'] as List)
          if (rawP is Map)
            PropertyItem(
              propertyType: [
                if (rawP['propertyType'] is List)
                  for (final t in rawP['propertyType'] as List) t.toString(),
              ],
              propertyTypeOther: (rawP['propertyTypeOther'] ?? '').toString(),
              khatianNo: (rawP['khatianNo'] ?? '').toString(),
              dagNoCs: (rawP['dagNoCs'] ?? '').toString(),
              dagNoRs: (rawP['dagNoRs'] ?? '').toString(),
              holdingNumber: (rawP['holdingNumber'] ?? '').toString(),
              landQuantity: (rawP['landQuantity'] ?? '').toString(),
              myShareQuantity: (rawP['myShareQuantity'] ?? '').toString(),
              ownership: switch (rawP['ownership']) {
                'joint' => OwnershipType.joint,
                'single' => OwnershipType.single,
                _ => OwnershipType.unknown,
              },
              jointOwnerCount: (rawP['jointOwnerCount'] as num?)?.toInt(),
              applicableDocs: [
                if (rawP['applicableDocs'] is List)
                  for (final rawDoc in rawP['applicableDocs'] as List)
                    if (rawDoc is Map)
                      ApplicableDoc(
                        type: (rawDoc['type'] ?? '').toString(),
                        fileName: (rawDoc['fileName'] ?? '').toString(),
                        // path stays null — re-attach required after restore.
                      ),
              ],
            ),
    ];

    final nominees = <Nominee>[
      if (value['nominees'] is List)
        for (final rawN in value['nominees'] as List)
          if (rawN is Map)
            Nominee(
              name: (rawN['name'] ?? '').toString(),
              relation: (rawN['relation'] ?? '').toString(),
              mobile: (rawN['mobile'] ?? '').toString(),
              address: (rawN['address'] ?? '').toString(),
            ),
    ];

    return RegistrationForm(
      fullName: (value['fullName'] ?? '').toString(),
      fatherOrHusband: (value['fatherOrHusband'] ?? '').toString(),
      mother: (value['mother'] ?? '').toString(),
      dob: (value['dob'] ?? '').toString(),
      nationality: (value['nationality'] ?? 'বাংলাদেশী').toString(),
      occupation: (value['occupation'] ?? '').toString(),
      nid: (value['nid'] ?? '').toString(),
      mobile: (value['mobile'] ?? '').toString(),
      gender: switch (value['gender']) {
        'male' => Gender.male,
        'female' => Gender.female,
        _ => Gender.unknown,
      },
      email: (value['email'] ?? '').toString(),
      permanentAddress: addressJson(value['permanentAddress']),
      currentAddress: addressJson(value['currentAddress']),
      sameAsCurrentAddress: value['sameAsCurrentAddress'] == true,
      urgentContactName: (value['urgentContactName'] ?? '').toString(),
      urgentContactRelation: (value['urgentContactRelation'] ?? '').toString(),
      urgentContactMobile: (value['urgentContactMobile'] ?? '').toString(),
      urgentContactAddress: (value['urgentContactAddress'] ?? '').toString(),
      propertyCount: (value['propertyCount'] as num?)?.toInt(),
      properties: properties,
      nominees: nominees.isEmpty ? const [Nominee()] : nominees,
      receiptNo: (value['receiptNo'] ?? '').toString(),
      paymentMethod: _paymentMethodFromName((value['paymentMethod'] ?? '').toString()),
      receiptFile: fileRefJson(value['receiptFile']),
      memberPhoto: fileRefJson(value['memberPhoto']),
      // memberSignature is never restored (a drawing cannot be persisted).
      memberSignature: '',
      submissionDate: (value['submissionDate'] ?? '').toString(),
      declarationAccepted: value['declarationAccepted'] == true,
    );
  }

  Map<String, dynamic> _addressJson(AddressDetail a) => {
        'house': a.house,
        'road': a.road,
        'postOffice': a.postOffice,
        'upazila': a.upazila,
        'district': a.district,
        'division': a.division,
      };
}

PaymentMethod _paymentMethodFromName(String name) => switch (name) {
      'cash' => PaymentMethod.cash,
      'bank' => PaymentMethod.bank,
      'mfs' => PaymentMethod.mfs,
      'other' => PaymentMethod.other,
      _ => PaymentMethod.unknown,
    };
