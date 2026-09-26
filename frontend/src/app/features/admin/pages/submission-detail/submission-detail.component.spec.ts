import { TestBed } from '@angular/core/testing';
import { ActivatedRoute, Router } from '@angular/router';
import { provideTranslateService } from '@ngx-translate/core';
import { of } from 'rxjs';
import { vi } from 'vitest';
import { AdminService } from '../../../../core/services/admin.service';
import type { SubmissionDetail } from '../../../../core/models/admin.model';
import { SubmissionDetailComponent } from './submission-detail.component';

const submission: SubmissionDetail = {
  id: '1',
  status: 'pending',
  fullName: 'JANE DOE',
  mobile: '01711111111',
  createdAt: '2026-01-01T00:00:00Z',
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
  properties: [
    {
      id: 'p1',
      propertyType: ['residential'],
      propertyTypeOther: null,
      khatianNo: '10',
      dagNoCs: null,
      dagNoRs: null,
      holdingNumber: null,
      landQuantity: '1.5',
      ownership: 'যৌথ',
      coOwners: [
        { id: 'c1', name: 'Jane Doe', mobile: '01711111111' },
        { id: 'c2', name: 'John Doe', mobile: '01711111111' },
        { id: 'c3', name: 'Other', mobile: '01822222222' },
      ],
      applicableDocs: [],
    },
  ],
  nominees: [
    { id: 'n1', name: 'John Doe', relation: 'father', mobile: '01711111111', sharePercentage: 60 },
    { id: 'n2', name: 'Sam Doe', relation: 'son', mobile: '01933333333', sharePercentage: 40 },
  ],
  admissionFee: '500',
  subscription: '60',
  receiptNo: '1',
  paymentMethod: 'cash',
};

describe('SubmissionDetailComponent (OnPush + memoized derived values)', () => {
  function create() {
    TestBed.configureTestingModule({
      imports: [SubmissionDetailComponent],
      providers: [
        provideTranslateService(),
        {
          provide: ActivatedRoute,
          useValue: { snapshot: { paramMap: new Map([['id', '1']]) } },
        },
        { provide: Router, useValue: { navigate: vi.fn() } },
        { provide: AdminService, useValue: { getSubmission: () => of(submission) } },
      ],
    });
    const fixture = TestBed.createComponent(SubmissionDetailComponent);
    fixture.detectChanges();
    fixture.detectChanges();
    return fixture;
  }

  it('renders the loaded submission', () => {
    const fixture = create();
    const text: string = fixture.nativeElement.textContent;
    expect(fixture.componentInstance.submission).not.toBeNull();
    expect(text).toContain('JANE DOE');
  });

  it('derives initials and emergency-contact facts from the submission', () => {
    const component = create().componentInstance;
    expect(component.applicantInitials).toBe('JD');
    expect(component.emergencyContact?.name).toBe('John Doe');
    // The emergency contact shares the applicant's mobile, which `samePerson`
    // treats as a match, and also appears among the nominees.
    expect(component.emergencyIsApplicant).toBe(true);
    expect(component.emergencyAlsoNominee).toBe(true);
    expect(component.nomineeShareTotal).toBe(100);
    expect(component.nomineeShareDeclared).toBe(true);
    expect(component.nomineeShareWarning).toBe(false);
  });

  it('returns identical references for repeated derived reads', () => {
    const component = create().componentInstance;
    const first = component.emergencyContact;
    expect(component.emergencyContact).toBe(first);
    expect(component.nomineeShareTotal).toBe(component.nomineeShareTotal);

    const property = component.submission!.properties[0];
    expect(component.duplicateMobiles(property)).toBe(component.duplicateMobiles(property));
    expect(component.coOwnerRoles(property.coOwners[0])).toBe(
      component.coOwnerRoles(property.coOwners[0]),
    );
  });

  it('flags the mobile shared by two co-owners but not the unique one', () => {
    const component = create().componentInstance;
    const property = component.submission!.properties[0];
    expect(component.isDuplicateMobile(property, property.coOwners[0])).toBe(true);
    expect(component.isDuplicateMobile(property, property.coOwners[1])).toBe(true);
    expect(component.isDuplicateMobile(property, property.coOwners[2])).toBe(false);
    expect(component.coOwnerRoles(property.coOwners[0])).toEqual([
      'applicant',
      'emergency',
      'nominee',
    ]);
    expect(component.coOwnerRoles(property.coOwners[2])).toEqual([]);
  });

  it('sanitizes the preview frame URL only once per preview target', () => {
    const component = create().componentInstance;
    const first = component.previewFrameUrl;
    expect(component.previewFrameUrl).toBe(first);

    component.openDocPreview({ id: 'd1', docType: 'deed', fileUrl: '/uploads/a.pdf' });
    const next = component.previewFrameUrl;
    expect(next).not.toBe(first);
    expect(component.previewFrameUrl).toBe(next);
  });

  it('collapses and re-expands a property without recomputing derived state', () => {
    const fixture = create();
    const component = fixture.componentInstance;
    expect(component.isPropertyExpanded('p1')).toBe(true);
    component.toggleProperty('p1');
    expect(component.isPropertyExpanded('p1')).toBe(false);
    component.toggleProperty('p1');
    expect(component.isPropertyExpanded('p1')).toBe(true);
    fixture.detectChanges();
    expect(component.submission!.id).toBe('1');
  });
});
