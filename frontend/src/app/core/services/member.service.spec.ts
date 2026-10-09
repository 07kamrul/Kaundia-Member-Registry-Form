import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { MemberService, type MemberProfile } from './member.service';
import { toNeighbourOwner, type NeighbourDirectory } from '../models/neighbour.model';

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

describe('MemberService neighbour directory and profile preference', () => {
  let http: HttpTestingController;
  let service: MemberService;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [provideHttpClient(), provideHttpClientTesting()] });
    http = TestBed.inject(HttpTestingController);
    service = TestBed.inject(MemberService);
  });
  afterEach(() => http.verify());

  const API = {
    dag_type: 'cs',
    plot_limit: 5,
    properties: [
      {
        own: { property_id: 12, rs_dag: '830', cs_dag: '412', land_quantity: '5', dag_number: 412 },
        same_dag_owners: [
          { owner_name: 'A', mobile: '01712345678', contact_hidden: false, land_quantity: '5', rs_dag: '830', cs_dag: '412', position_label: 'same_dag' },
        ],
        neighbours: [
          { owner_name: 'B', mobile: null, contact_hidden: true, land_quantity: null, rs_dag: null, cs_dag: '413', position_label: 'mystery' },
        ],
      },
    ],
  };

  it('getNeighbours omits dag_type when not given', () => {
    service.getNeighbours().subscribe();
    const req = http.expectOne((r) => r.url.endsWith('/member/neighbours'));
    expect(req.request.params.has('dag_type')).toBe(false);
    req.flush(API);
  });

  it('getNeighbours sends dag_type and maps snake_case safely', () => {
    let result: NeighbourDirectory | undefined;
    service.getNeighbours('cs').subscribe((d) => (result = d));
    const req = http.expectOne((r) => r.url.endsWith('/member/neighbours'));
    expect(req.request.params.get('dag_type')).toBe('cs');
    req.flush(API);
    expect(result!.dagType).toBe('cs');
    expect(result!.plotLimit).toBe(5);
    expect(result!.properties[0].own).toEqual({ propertyId: 12, rsDag: '830', csDag: '412', landQuantity: '5', dagNumber: 412 });
    expect(result!.properties[0].sameDagOwners[0]).toEqual({
      ownerName: 'A', mobile: '01712345678', contactHidden: false, landQuantity: '5', rsDag: '830', csDag: '412', positionLabel: 'same_dag',
    });
    const hidden = result!.properties[0].neighbours[0];
    expect(hidden.mobile).toBeNull();
    expect(hidden.contactHidden).toBe(true);
    expect(hidden.positionLabel).toBe('near');
  });

  it('never exposes a mobile flagged as hidden', () => {
    expect(toNeighbourOwner({ owner_name: 'X', mobile: '017', contact_hidden: true, land_quantity: null, rs_dag: null, cs_dag: null, position_label: 'adjacent' }).mobile).toBeNull();
  });

  it('maps showInNeighbourDirectory, defaulting to true', () => {
    let profile: MemberProfile | undefined;
    service.getProfile().subscribe((p) => (profile = p));
    http.expectOne((r) => r.url.endsWith('/member/me')).flush({ ...API_PROFILE });
    expect(profile!.showInNeighbourDirectory).toBe(true);

    service.clearProfileCache();
    service.getProfile().subscribe((p) => (profile = p));
    http.expectOne((r) => r.url.endsWith('/member/me')).flush({ ...API_PROFILE, show_in_neighbour_directory: false });
    expect(profile!.showInNeighbourDirectory).toBe(false);
  });

  it('updateProfile sends the preference as a boolean', () => {
    service.updateProfile({ showInNeighbourDirectory: false }).subscribe();
    const req = http.expectOne((r) => r.url.endsWith('/member/profile'));
    expect(req.request.body).toEqual({ show_in_neighbour_directory: false });
    req.flush({ ...API_PROFILE, show_in_neighbour_directory: false });
  });
});
