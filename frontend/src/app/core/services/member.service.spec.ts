import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { MemberService, type MemberProfile } from './member.service';

const API_PROFILE = {
  member_id: 'UKAMKS-1',
  status: 'approved',
  full_name: 'Md. Kamrul Hasan',
  father_or_husband: 'Abul Kasem',
  mother: 'Hazer Begum',
  dob: '1996-01-07',
  nationality: 'Bangladeshi',
  gender: 'পুরুষ',
  mobile: '01758290421',
  email: 'a@b.com',
  permanent_house: 'H-1',
  current_division: 'Dhaka',
  urgent_contact_name: 'Rahim',
  admission_fee: '1000',
  payment_method: 'ক্যাশ',
  submission_date: '2026-01-01',
  member_photo_path: 'photos/member_1/a.jpg',
  properties: [
    {
      id: 4,
      property_type: ['জমি'],
      khatian_no: '2025-100801',
      my_share_quantity: '3',
      co_owners: [{ id: 1, owner_name: 'Karim', owner_phone: '017' }],
      applicable_docs: [{ id: 2, doc_type: 'খতিয়ান', file_path: 'documents/x.pdf' }],
    },
  ],
  nominees: [{ id: 9, name: 'Nomi', relation: 'Wife', mobile: '018', address: null }],
};

describe('MemberService.getProfile', () => {
  it('maps every registration field, including nominees and property detail', () => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    const http = TestBed.inject(HttpTestingController);
    let result: MemberProfile | undefined;

    TestBed.inject(MemberService)
      .getProfile()
      .subscribe((p) => (result = p));
    http.expectOne((r) => r.url.endsWith('/member/me')).flush(API_PROFILE);

    expect(result!.gender).toBe('পুরুষ');
    expect(result!.permanentHouse).toBe('H-1');
    expect(result!.currentDivision).toBe('Dhaka');
    expect(result!.urgentContactName).toBe('Rahim');
    expect(result!.admissionFee).toBe('1000');
    expect(result!.memberPhotoUrl).toContain('/uploads/photos/member_1/a.jpg');
    expect(result!.nominees[0]).toEqual({
      id: 9, name: 'Nomi', relation: 'Wife', mobile: '018', address: undefined,
    });
    expect(result!.properties[0].myShareQuantity).toBe('3');
    expect(result!.properties[0].coOwners[0].ownerName).toBe('Karim');
    expect(result!.properties[0].applicableDocs[0].fileUrl).toContain('/uploads/documents/x.pdf');
  });
});
