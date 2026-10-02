import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { MemberService } from './member.service';
import { RegistrationService } from './registration.service';
import type { FormDataModel } from '../models/registration.model';

describe('MemberService (self-service methods)', () => {
  let http: HttpTestingController;
  let service: MemberService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    http = TestBed.inject(HttpTestingController);
    service = TestBed.inject(MemberService);
  });
  afterEach(() => http.verify());

  it('changePassword posts snake_case fields', () => {
    let done: unknown;
    service.changePassword('old', 'new-pass').subscribe((r) => (done = r));
    const req = http.expectOne((r) => r.url.endsWith('/member/change-password'));
    expect(req.request.body).toEqual({ current_password: 'old', new_password: 'new-pass' });
    req.flush(null);
    expect(done).toBeNull();
  });

  it('updateProfile camelCases keys to snake_case and clears the profile cache', () => {
    let profile: unknown;
    service
      .updateProfile({ fullName: 'New Name', occupation: 'Engineer' })
      .subscribe((p) => (profile = p));
    const req = http.expectOne((r) => r.url.endsWith('/member/profile'));
    expect(req.request.method).toBe('PATCH');
    expect(req.request.body).toEqual({ full_name: 'New Name', occupation: 'Engineer' });
    req.flush({
      member_id: 'UKAMKS-1',
      status: 'pending',
      full_name: 'New Name',
      occupation: 'Engineer',
      mobile: '017',
      email: 'x@y.z',
      properties: [],
      nominees: [],
    });
    expect((profile as { fullName: string }).fullName).toBe('New Name');
  });

  it('uploadPhoto posts the file as multipart and clears the cache', () => {
    let profile: unknown;
    const file = new File(['x'], 'me.png');
    service.uploadPhoto(file).subscribe((p) => (profile = p));
    const req = http.expectOne((r) => r.url.endsWith('/member/me/photo'));
    expect(req.request.body).toBeInstanceOf(FormData);
    req.flush({
      member_id: 'UKAMKS-1',
      status: 'approved',
      full_name: 'X',
      mobile: '017',
      email: 'x@y.z',
      properties: [],
      nominees: [],
      member_photo_path: 'photos/member_1/me.png',
    });
    expect((profile as { memberPhotoUrl: string }).memberPhotoUrl).toContain(
      '/uploads/photos/member_1/me.png',
    );
  });

  it('getInstallments, getPicnicPayments, getPicnicRates map snake_case to camelCase', () => {
    let installments: unknown;
    service.getInstallments().subscribe((r) => (installments = r));
    http.expectOne((r) => r.url.endsWith('/member/installments')).flush([
      {
        id: 1,
        year: 2026,
        month: 1,
        amount: 100,
        status: 'paid',
        paid_at: '2026-01-05T00:00:00Z',
      },
    ]);
    expect(installments).toEqual([
      { id: '1', year: 2026, month: 1, amount: 100, status: 'paid', paidAt: '2026-01-05T00:00:00Z' },
    ]);

    let payments: unknown;
    service.getPicnicPayments().subscribe((r) => (payments = r));
    http.expectOne((r) => r.url.endsWith('/member/picnic-payments')).flush([
      {
        id: 2,
        head_price: 300,
        additional_price: 150,
        additional_count: 1,
        total: 450,
        additional_heads: [{ name: 'Guest', relation: 'Friend' }],
        payment_date: '2026-02-01',
        receipt_no: 'R1',
        payment_method: 'Cash',
        created_at: '2026-02-01T00:00:00Z',
      },
    ]);
    expect(payments).toEqual([
      {
        id: 2,
        headPrice: 300,
        additionalPrice: 150,
        additionalCount: 1,
        total: 450,
        additionalHeads: [{ name: 'Guest', relation: 'Friend' }],
        paymentDate: '2026-02-01',
        receiptNo: 'R1',
        paymentMethod: 'Cash',
        createdAt: '2026-02-01T00:00:00Z',
      },
    ]);

    let rates: unknown;
    service.getPicnicRates('2026-02-01').subscribe((r) => (rates = r));
    const req = http.expectOne((r) => r.url.endsWith('/member/picnic-rates'));
    expect(req.request.params.get('payment_date')).toBe('2026-02-01');
    req.flush({
      head_fee: 300,
      additional_head_fee: 150,
      unit: 'taka',
      effective_from: '2026-01-01',
    });
    expect(rates).toEqual({
      headFee: 300,
      additionalHeadFee: 150,
      unit: 'taka',
      effectiveFrom: '2026-01-01',
    });
  });

  it('createPicnicPayment posts snake_case fields and maps the response', () => {
    let payment: unknown;
    service
      .createPicnicPayment({
        additionalHeads: 2,
        additionalPeople: [{ name: 'A', relation: 'Friend' }],
        paymentDate: '2026-02-01',
        receiptNo: 'R9',
        paymentMethod: 'bKash',
      })
      .subscribe((p) => (payment = p));
    const req = http.expectOne((r) => r.url.endsWith('/member/picnic-payments'));
    expect(req.request.body).toEqual({
      additional_heads: 2,
      additional_people: [{ name: 'A', relation: 'Friend' }],
      payment_date: '2026-02-01',
      receipt_no: 'R9',
      payment_method: 'bKash',
    });
    req.flush({
      id: 3,
      head_price: 300,
      additional_price: 150,
      additional_count: 2,
      total: 600,
      additional_heads: [{ name: 'A', relation: 'Friend' }],
      payment_date: '2026-02-01',
      receipt_no: 'R9',
      payment_method: 'bKash',
      created_at: '2026-02-01T00:00:00Z',
    });
    expect(payment).toMatchObject({ id: 3, total: 600, additionalCount: 2 });
  });
});

describe('RegistrationService.submit', () => {
  let http: HttpTestingController;
  let service: RegistrationService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    http = TestBed.inject(HttpTestingController);
    service = TestBed.inject(RegistrationService);
  });
  afterEach(() => http.verify());

  function formData(overrides: Partial<FormDataModel> = {}): FormDataModel {
    return {
      fullName: 'Test User',
      fatherOrHusband: 'Father',
      mother: 'Mother',
      dob: '1990-01-01',
      nationality: 'Bangladeshi',
      occupation: 'Job',
      nid: '1234567890',
      mobile: '01700000000',
      gender: 'পুরুষ',
      email: 't@e.com',
      urgentContactName: 'U',
      urgentContactRelation: 'Brother',
      urgentContactMobile: '018',
      urgentContactAddress: 'Addr',
      propertyCount: 1,
      properties: [
        {
          propertyType: ['কৃষি জমি'],
          propertyTypeOther: '',
          khatianNo: '1',
          dagNo: { cs: '2', rs: '3' },
          holdingNumber: '',
          landQuantity: '10',
          myShareQuantity: '2',
          ownership: 'যৌথ',
          jointOwnerCount: 3,
          applicableDocs: [
            { type: 'খাজনা/কর রশিদ', fileName: 'r.pdf', fileDataUrl: 'data:application/pdf;base64,AAAA' },
          ],
        },
      ],
      nominees: [{ name: 'N', relation: 'Son', mobile: '019', address: 'A' }],
      admissionFee: 500 as unknown as string,
      subscription: '100',
      receiptNo: 'R-1',
      paymentMethod: 'Cash',
      memberSignature: '',
      submissionDate: '2026-10-02',
      memberPhoto: 'data:image/png;base64,CCCC',
      receiptFileDataUrl: 'data:image/png;base64,DDDD',
      receiptFileName: 'receipt.png',
      ...overrides,
    } as FormDataModel;
  }

  it('builds the snake_case payload and appends photo, receipt and doc files', () => {
    let result: unknown;
    service.submit(formData()).subscribe((r) => (result = r));

    const req = http.expectOne((r) => r.url.endsWith('/submissions'));
    expect(req.request.method).toBe('POST');
    const body = req.request.body as FormData;
    const payload = JSON.parse(body.get('payload') as string);
    expect(payload.full_name).toBe('Test User');
    expect(payload.permanent_address).toBeNull();
    expect(payload.properties[0].dag_no_cs).toBe('2');
    expect(payload.properties[0].joint_owner_count).toBe(3);
    expect(payload.properties[0].applicable_docs).toEqual([{ doc_type: 'খাজনা/কর রশিদ' }]);
    expect(payload.admission_fee).toBe('500');
    // photo + receipt + 1 doc
    expect(body.getAll('member_photo')).toHaveLength(1);
    expect(body.getAll('receipt_photo')).toHaveLength(1);
    expect(body.getAll('doc_files')).toHaveLength(1);

    req.flush({ id: 1, status: 'pending' });
    expect(result).toEqual({ id: 1, status: 'pending' });
  });

  it('omits receipt/photo/doc files when none are attached', () => {
    service
      .submit(
        formData({
          memberPhoto: undefined,
          receiptFileDataUrl: undefined,
          properties: [
            {
              propertyType: ['কৃষি জমি'],
              propertyTypeOther: '',
              khatianNo: '1',
              dagNo: { cs: '', rs: '' },
              holdingNumber: '',
              landQuantity: '10',
              myShareQuantity: '2',
              ownership: 'একক',
              jointOwnerCount: 1,
              applicableDocs: [],
            },
          ],
        }),
      )
      .subscribe();
    const req = http.expectOne((r) => r.url.endsWith('/submissions'));
    const body = req.request.body as FormData;
    expect(body.getAll('member_photo')).toHaveLength(0);
    expect(body.getAll('receipt_photo')).toHaveLength(0);
    expect(body.getAll('doc_files')).toHaveLength(0);
    const payload = JSON.parse(body.get('payload') as string);
    expect(payload.properties[0].joint_owner_count).toBeNull();
    req.flush({ id: 2, status: 'pending' });
  });
});
