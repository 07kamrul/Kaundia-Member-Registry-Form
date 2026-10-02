import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { provideTranslateService } from '@ngx-translate/core';
import { vi } from 'vitest';
import { AdminService } from '../../../../../core/services/admin.service';
import type { MemberProfile } from '../../../../../core/models/admin.model';
import { MemberDetailDrawerComponent } from './member-detail-drawer.component';

const profile: MemberProfile = {
  id: '1',
  memberId: 'UKAMKS-1',
  status: 'approved',
  fullName: 'JANE DOE',
  mobile: '01711111111',
  createdAt: '2026-01-01T00:00:00Z',
  updatedAt: '2026-02-01T00:00:00Z',
  fatherOrHusband: 'John Doe',
  mother: 'Mary Doe',
  dob: '1990-01-01',
  nationality: 'Bangladeshi',
  occupation: 'Engineer',
  nid: '1234567890',
  gender: 'female',
  email: 'jane@example.com',
  urgentContactName: 'John Doe',
  urgentContactRelation: 'father',
  urgentContactMobile: '01711111111',
  urgentContactAddress: 'Dhaka',
  properties: [],
  nominees: [],
  admissionFee: '500',
  subscription: '60',
  receiptNo: '1',
  paymentMethod: 'cash',
  feeSummary: { dueCount: 0, paidCount: 0, dueTotal: 0, paidTotal: 0 },
  installments: [],
  picnicPayments: [],
  auditTrail: [],
};

describe('MemberDetailDrawerComponent (read-only view from সদস্য তালিকা)', () => {
  function create(memberId: string | null) {
    TestBed.configureTestingModule({
      providers: [
        provideTranslateService(),
        { provide: AdminService, useValue: { getMemberProfile: () => of(profile) } },
      ],
    });
    const fixture = TestBed.createComponent(MemberDetailDrawerComponent);
    fixture.componentRef.setInput('memberId', memberId);
    fixture.detectChanges();
    fixture.detectChanges();
    return fixture;
  }

  it('renders the member record without any approve/reject review actions', () => {
    const fixture = create('1');
    const html: string = fixture.nativeElement.innerHTML;
    expect(fixture.componentInstance.profile).not.toBeNull();
    // The drawer is a read-only view: no decision buttons or reason form.
    expect(html).not.toContain('approveMembership');
    expect(html).not.toContain('rejectSubmission');
    expect(fixture.nativeElement.querySelector('button[data-action="approve"]')).toBeNull();
    expect(fixture.nativeElement.querySelector('button[data-action="reject"]')).toBeNull();
    expect(fixture.nativeElement.querySelector('textarea')).toBeNull();
  });

  it('shows the member id for the viewed member', () => {
    const fixture = create('1');
    const text: string = fixture.nativeElement.textContent;
    expect(text).toContain('UKAMKS-1');
  });

  it('stays closed (no request, no profile) when memberId is null', () => {
    const calls: string[] = [];
    TestBed.overrideProvider(AdminService, {
      useValue: {
        getMemberProfile: () => {
          calls.push('load');
          return of(profile);
        },
      },
    });
    const fixture = create(null);
    expect(calls).toEqual([]);
    expect(fixture.componentInstance.profile).toBeNull();
    expect(fixture.componentInstance.loading).toBe(false);
  });
});
