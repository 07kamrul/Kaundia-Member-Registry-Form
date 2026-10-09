import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { provideTranslateService } from '@ngx-translate/core';
import { of, throwError } from 'rxjs';
import { vi } from 'vitest';
import { MemberService, type MemberProfile } from '../../../../core/services/member.service';
import { ProfileComponent } from './profile.component';

const PROFILE = {
  memberId: 'UKAMKS-1',
  status: 'approved',
  fullName: 'Test',
  fatherOrHusband: 'F',
  mother: 'M',
  dob: '2000-01-01',
  mobile: '+8801712345678',
  showInNeighbourDirectory: true,
  properties: [],
  nominees: [],
} as MemberProfile;

function setup(updateProfile = vi.fn((p: object) => of({ ...PROFILE, ...p } as MemberProfile))) {
  TestBed.configureTestingModule({
    imports: [ProfileComponent],
    providers: [
      provideRouter([]),
      provideTranslateService(),
      {
        provide: MemberService,
        useValue: {
          getProfile: () => of(PROFILE),
          getPropertyRequests: () => of([]),
          updateProfile,
        },
      },
    ],
  });
  const fixture = TestBed.createComponent(ProfileComponent);
  fixture.detectChanges();
  const toggle = fixture.nativeElement.querySelector(
    '.neighbour-directory-pref input[type="checkbox"]',
  ) as HTMLInputElement;
  return { fixture, toggle, updateProfile };
}

describe('ProfileComponent neighbour-directory preference', () => {
  it('renders the toggle checked from the profile', () => {
    const { toggle } = setup();
    expect(toggle).not.toBeNull();
    expect(toggle.checked).toBe(true);
  });

  it('PATCHes only the boolean and never flags a re-review', () => {
    const { fixture, toggle, updateProfile } = setup();
    toggle.checked = false;
    toggle.dispatchEvent(new Event('change'));
    expect(updateProfile).toHaveBeenCalledWith({ showInNeighbourDirectory: false });
    expect(fixture.componentInstance.profile!.showInNeighbourDirectory).toBe(false);
    expect(fixture.componentInstance.profile!.status).toBe('approved');

    fixture.componentInstance.startEdit();
    expect(fixture.componentInstance.willRequeue).toBe(false);
  });

  it('reverts the toggle when saving fails', () => {
    const { fixture, toggle } = setup(vi.fn(() => throwError(() => new Error('down'))));
    toggle.checked = false;
    toggle.dispatchEvent(new Event('change'));
    expect(toggle.checked).toBe(true);
    expect(fixture.componentInstance.profile!.showInNeighbourDirectory).toBe(true);
    expect(fixture.componentInstance.directoryError).not.toBe('');
  });
});
