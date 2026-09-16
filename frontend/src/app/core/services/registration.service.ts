import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import type { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import type { FormDataModel, SubmissionResult } from '../models/registration.model';

// Converts a "data:<mime>;base64,..." URL (how photo/doc uploads are held
// in the form model) back into a Blob for multipart upload.
function dataUrlToBlob(dataUrl: string): Blob {
  const [header, base64] = dataUrl.split(',');
  const mime = header.match(/data:(.*);base64/)?.[1] ?? 'application/octet-stream';
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return new Blob([bytes], { type: mime });
}

@Injectable({ providedIn: 'root' })
export class RegistrationService {
  constructor(private http: HttpClient) {}

  // Backend contract (see backend/app/api/routes/submissions.py): a single
  // 'payload' form field holding a JSON object matching SubmissionPayload
  // (snake_case, nested properties/nominees), plus an optional
  // 'member_photo' file, plus a 'doc_files' list whose order matches each
  // property's applicable_docs flattened in property order.
  submit(formData: FormDataModel): Observable<SubmissionResult> {
    const body = new FormData();

    const jsonPayload = {
      full_name: formData.fullName,
      father_or_husband: formData.fatherOrHusband,
      mother: formData.mother,
      dob: formData.dob,
      nationality: formData.nationality,
      occupation: formData.occupation,
      nid: formData.nid,
      mobile: formData.mobile,
      gender: formData.gender,
      email: formData.email,
      permanent_address: formData.permanentAddress
        ? {
            house: formData.permanentAddress.house,
            road: formData.permanentAddress.road,
            post_office: formData.permanentAddress.postOffice,
            upazila: formData.permanentAddress.upazila,
            district: formData.permanentAddress.district,
          }
        : null,
      current_address: formData.currentAddress
        ? {
            house: formData.currentAddress.house,
            road: formData.currentAddress.road,
            post_office: formData.currentAddress.postOffice,
            upazila: formData.currentAddress.upazila,
            district: formData.currentAddress.district,
          }
        : null,
      urgent_contact_name: formData.urgentContactName,
      urgent_contact_relation: formData.urgentContactRelation,
      urgent_contact_mobile: formData.urgentContactMobile,
      urgent_contact_address: formData.urgentContactAddress,
      admission_fee: formData.admissionFee,
      subscription: formData.subscription,
      receipt_no: formData.receiptNo,
      payment_method: formData.paymentMethod,
      member_signature: formData.memberSignature,
      submission_date: formData.submissionDate,
      properties: formData.properties.map((property) => ({
        property_type: property.propertyType,
        property_type_other: property.propertyTypeOther,
        khatian_no: property.khatianNo,
        dag_no_cs: property.dagNo.cs,
        dag_no_rs: property.dagNo.rs,
        land_quantity: property.landQuantity,
        ownership: property.ownership,
        co_owners: property.coOwners.map((coOwner) => ({
          owner_name: coOwner.ownerName,
          owner_phone: coOwner.ownerPhone,
        })),
        applicable_docs: property.applicableDocs.map((doc) => ({ doc_type: doc.type })),
      })),
      nominees: formData.nominees,
    };

    body.append('payload', JSON.stringify(jsonPayload));

    if (formData.memberPhoto) {
      body.append('member_photo', dataUrlToBlob(formData.memberPhoto), 'photo.jpg');
    }

    for (const property of formData.properties) {
      for (const doc of property.applicableDocs) {
        if (doc.fileDataUrl) {
          body.append('doc_files', dataUrlToBlob(doc.fileDataUrl), doc.fileName || 'document');
        }
      }
    }

    return this.http.post<SubmissionResult>(`${environment.apiBaseUrl}/submissions`, body);
  }
}
