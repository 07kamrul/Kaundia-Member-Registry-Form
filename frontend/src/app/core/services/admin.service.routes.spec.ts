import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { AdminService } from './admin.service';

describe('AdminService route coverage', () => {
  let http: HttpTestingController;
  let service: AdminService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    http = TestBed.inject(HttpTestingController);
    service = TestBed.inject(AdminService);
  });

  afterEach(() => http.verify());

  it('listSubmissions builds the status query param', () => {
    let rows: unknown;
    service.listSubmissions('pending').subscribe((r) => (rows = r));
    http
      .expectOne((r) => r.url.endsWith('/admin/submissions?status=pending'))
      .flush([]);
    expect(rows).toEqual([]);

    let all: unknown;
    service.listSubmissions().subscribe((r) => (all = r));
    http.expectOne((r) => r.url.endsWith('/admin/submissions')).flush([]);
    expect(all).toEqual([]);
  });

  it('approve/reject/resend hit the submission action endpoints', () => {
    let approved: unknown;
    service.approveSubmission('5').subscribe((r) => (approved = r));
    http.expectOne((r) => r.url.endsWith('/admin/submissions/5/approve')).flush({
      member_id: 'UKAMKS-1',
    });
    expect(approved).toEqual({ member_id: 'UKAMKS-1' });

    let rejected: unknown;
    service.rejectSubmission('5', 'bad docs').subscribe((r) => (rejected = r));
    const rejectReq = http.expectOne((r) => r.url.endsWith('/admin/submissions/5/reject'));
    expect(rejectReq.request.body).toEqual({ reason: 'bad docs' });
    rejectReq.flush({ status: 'rejected', email_sent: true });
    expect(rejected).toEqual({ emailSent: true }); // RejectResult is emailSent-only

    let resent: unknown;
    service.resendRejectionNotification('5').subscribe((r) => (resent = r));
    http
      .expectOne((r) => r.url.endsWith('/admin/submissions/5/resend-notification'))
      .flush({ status: 'rejected', email_sent: false });
    expect(resent).toEqual({ emailSent: false });
  });

  it('getSubmission loads and maps the detail graph', () => {
    let detail: unknown;
    service.getSubmission('7').subscribe((d) => (detail = d));
    http.expectOne((r) => r.url.endsWith('/admin/submissions/7')).flush({
      id: 7,
      status: 'pending',
      full_name: 'Test User',
      mobile: '01700000000',
      created_at: '2026-01-01T00:00:00Z',
      father_or_husband: 'F',
      mother: 'M',
      dob: '1990-01-01',
      nationality: 'Bangladeshi',
      occupation: 'Job',
      nid: '123',
      gender: 'পুরুষ',
      email: 't@e.com',
      urgent_contact_name: 'U',
      urgent_contact_relation: 'Brother',
      urgent_contact_mobile: '018',
      urgent_contact_address: 'Addr',
      properties: [],
      nominees: [],
      admission_fee: '500',
      subscription: '100',
      receipt_no: 'R',
      payment_method: 'Cash',
    });
    expect((detail as { fullName: string }).fullName).toBe('Test User');
  });

  it('replaceAttachment PUTs multipart to the kind-specific endpoint', () => {
    let done: unknown;
    const file = new File(['x'], 'photo.jpg');
    service.replaceAttachment('5', 'member_photo', file).subscribe((r) => (done = r));
    const req = http.expectOne((r) =>
      r.url.endsWith('/admin/submissions/5/attachments/member_photo'),
    );
    expect(req.request.method).toBe('PUT');
    expect(req.request.body).toBeInstanceOf(FormData);
    req.flush({
      id: 5,
      status: 'pending',
      full_name: 'Test User',
      mobile: '01700000000',
      created_at: '2026-01-01T00:00:00Z',
      father_or_husband: 'F',
      mother: 'M',
      dob: '1990-01-01',
      nationality: 'Bangladeshi',
      occupation: 'Job',
      nid: '123',
      gender: 'পুরুষ',
      email: 't@e.com',
      urgent_contact_name: 'U',
      urgent_contact_relation: 'Brother',
      urgent_contact_mobile: '018',
      urgent_contact_address: 'Addr',
      properties: [],
      nominees: [],
      admission_fee: '500',
      subscription: '100',
      receipt_no: 'R',
      payment_method: 'Cash',
    });
    expect((done as { fullName: string }).fullName).toBe('Test User');
  });

  it('member endpoints: list, profile, installments, delete, add/update installment', () => {
    service.listMembers().subscribe();
    http.expectOne((r) => r.url.endsWith('/admin/members')).flush([]);

    service.getMemberProfile('9').subscribe();
    http.expectOne((r) => r.url.endsWith('/admin/members/9')).flush({});

    service.getMemberInstallments('9').subscribe();
    http.expectOne((r) => r.url.endsWith('/admin/members/9/installments')).flush([]);

    let deleted: unknown;
    service.deleteMember('9').subscribe((r) => (deleted = r));
    const del = http.expectOne((r) => r.url.endsWith('/admin/members/9'));
    expect(del.request.method).toBe('DELETE');
    del.flush(null);
    expect(deleted).toBeNull();

    let added: unknown;
    service
      .addInstallment('9', { year: 2026, month: 1, amount: 100 })
      .subscribe((r) => (added = r));
    const add = http.expectOne((r) => r.url.endsWith('/admin/members/9/installments'));
    expect(add.request.method).toBe('POST');
    expect(add.request.body).toEqual({ year: 2026, month: 1, amount: 100 });
    add.flush({});
    expect(added).toEqual({});

    let updated: unknown;
    service.updateInstallment('3', 'paid').subscribe((r) => (updated = r));
    const upd = http.expectOne((r) => r.url.endsWith('/admin/installments/3'));
    expect(upd.request.method).toBe('PATCH');
    expect(upd.request.body).toEqual({ status: 'paid' });
    upd.flush({});
    expect(updated).toEqual({});
  });

  it('fee settings: active list, history, and version creation with mapping', () => {
    let active: unknown;
    service.getActiveFeeSettings().subscribe((r) => (active = r));
    http.expectOne((r) => r.url.endsWith('/admin/fee-settings')).flush([]);
    expect(active).toEqual([]);

    let history: unknown;
    service.getFeeSettingHistory('admission_fee').subscribe((r) => (history = r));
    http
      .expectOne((r) => r.url.includes('/admin/fee-settings/admission_fee/history'))
      .flush([]);
    expect(history).toEqual([]);

    let created: unknown;
    service
      .createFeeSettingVersion({ key: 'admission_fee', value: 600, startDate: '2026-10-02' })
      .subscribe((r) => (created = r));
    const req = http.expectOne((r) => r.url.endsWith('/admin/fee-settings'));
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({
      key: 'admission_fee',
      value: 600,
      unit: undefined,
      start_date: '2026-10-02',
    });
    req.flush({
      id: 12,
      key: 'admission_fee',
      value: 600,
      unit: null,
      start_date: '2026-10-02',
      end_date: null,
      status: 1,
    });
    expect(created).toEqual({
      id: '12',
      key: 'admission_fee',
      value: 600,
      unit: undefined,
      startDate: '2026-10-02',
      endDate: undefined,
      status: 1,
    });
  });

  it('audit log, config lists, notices and events CRUD hit their endpoints', () => {
    let entries: unknown;
    service.listAuditLog().subscribe((r) => (entries = r));
    http.expectOne((r) => r.url.endsWith('/admin/audit-log')).flush([
      {
        id: '7',
        actor_admin_id: 3,
        action: 'member.approve',
        entity_type: 'member',
        entity_id: '5',
        detail: 'd',
        created_at: '2026-01-01T00:00:00Z',
      },
    ]);
    expect(entries).toEqual([
      {
        id: '7',
        actorAdminId: '3',
        action: 'member.approve',
        entityType: 'member',
        entityId: '5',
        detail: 'd',
        createdAt: '2026-01-01T00:00:00Z',
      },
    ]);

    let items: unknown;
    service.listConfigListItems('cat').subscribe((r) => (items = r));
    http.expectOne((r) => r.url.includes('/admin/config-lists?category=cat')).flush([
      { id: 1, category: 'c', value: 'v', label: 'L', sort_order: 2, is_active: 1 },
      { id: 2, category: 'c', value: 'w', label: 'M', sort_order: 1, is_active: 0 },
    ]);
    expect(items).toEqual([
      { id: '1', category: 'c', value: 'v', label: 'L', sortOrder: 2, isActive: true },
      { id: '2', category: 'c', value: 'w', label: 'M', sortOrder: 1, isActive: false },
    ]);
    service.listConfigListItems().subscribe();
    http.expectOne((r) => r.url.endsWith('/admin/config-lists')).flush([]);

    service.createConfigListItem({ category: 'c', value: 'v', label: 'L' }).subscribe();
    const post = http.expectOne((r) => r.url.endsWith('/admin/config-lists'));
    expect(post.request.body).toEqual({ category: 'c', value: 'v', label: 'L', sort_order: 0 });
    post.flush({});

    service.updateConfigListItem('3', { isActive: false }).subscribe();
    const patch = http.expectOne((r) => r.url.endsWith('/admin/config-lists/3'));
    expect(patch.request.body).toEqual({ is_active: false, label: undefined, sort_order: undefined });
    patch.flush({});

    service.listNotices({ published: true }).subscribe();
    http.expectOne((r) => r.url.includes('/admin/notices?published=true')).flush([]);
    service.createNotice({ title: 'T', body: 'B' } as never).subscribe();
    http.expectOne((r) => r.url.endsWith('/admin/notices')).flush({});
    service.updateNotice('2', { title: 'T2', body: 'B' } as never).subscribe();
    http.expectOne((r) => r.url.endsWith('/admin/notices/2')).flush({});
    let noticeGone: unknown;
    service.deleteNotice('2').subscribe((r) => (noticeGone = r));
    http.expectOne((r) => r.url.endsWith('/admin/notices/2')).flush(null);

    service.listEvents({ categoryId: '4' }).subscribe();
    http.expectOne((r) => r.url.includes('/admin/events?category_id=4')).flush([]);
    service.createEvent({ title: 'E' } as never).subscribe();
    http.expectOne((r) => r.url.endsWith('/admin/events')).flush({});
    service.updateEvent('6', { title: 'E2' } as never).subscribe();
    http.expectOne((r) => r.url.endsWith('/admin/events/6')).flush({});
    let eventGone: unknown;
    service.deleteEvent('6').subscribe((r) => (eventGone = r));
    http.expectOne((r) => r.url.endsWith('/admin/events/6')).flush(null);
    expect(noticeGone).toBeNull();
    expect(eventGone).toBeNull();
  });

  it('getFeeTypes maps the catalog and createFeeTypeVersion posts snake_case', () => {
    let types: unknown;
    service.getFeeTypes().subscribe((t) => (types = t));
    http
      .expectOne((r) => r.url.endsWith('/admin/fee-types'))
      .flush([
        {
          key: 'development_fee',
          label_bn: 'উন্নয়ন ফি',
          label_en: 'Development Fee',
          calculation_type: 'fixed',
          unit: 'taka',
          is_recurring: false,
          is_pay_once: true,
          fee_category: 'other',
          is_active: true,
          sort_order: 3,
          created_at: '2026-10-11T00:00:00Z',
          current_version: {
            values: { development_fee: 500 },
            unit: 'taka',
            start_date: '2026-10-01',
          },
          payment_count: 2,
        },
      ]);
    expect(types).toEqual([
      {
        key: 'development_fee',
        labelBn: 'উন্নয়ন ফি',
        labelEn: 'Development Fee',
        calculationType: 'fixed',
        unit: 'taka',
        isRecurring: false,
        isPayOnce: true,
        feeCategory: 'other',
        isActive: true,
        sortOrder: 3,
        createdAt: '2026-10-11T00:00:00Z',
        currentVersion: {
          values: { development_fee: 500 },
          unit: 'taka',
          startDate: '2026-10-01',
        },
        paymentCount: 2,
      },
    ]);

    let versions: unknown;
    service
      .createFeeTypeVersion('development_fee', { value: 600, startDate: '2026-11-01' })
      .subscribe((v) => (versions = v));
    const req = http.expectOne((r) => r.url.endsWith('/admin/fee-types/development_fee/versions'));
    expect(req.request.body).toEqual({
      value: 600,
      base_amount: undefined,
      additional_rate: undefined,
      base_threshold: undefined,
      head_fee: undefined,
      additional_head_fee: undefined,
      min_amount: undefined,
      max_amount: undefined,
      unit: undefined,
      start_date: '2026-11-01',
    });
    req.flush([
      {
        start_date: '2026-11-01',
        end_date: null,
        status: 1,
        values: { development_fee: 600 },
      },
    ]);
    expect(versions).toEqual([
      { startDate: '2026-11-01', endDate: null, status: 1, values: { development_fee: 600 } },
    ]);
  });
});
