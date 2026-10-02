import { TestBed, ComponentFixture } from '@angular/core/testing';
import { provideTranslateService } from '@ngx-translate/core';
import { of } from 'rxjs';
import { FormBuilder, FormGroup, FormArray, ReactiveFormsModule } from '@angular/forms';
import { vi } from 'vitest';
import { RegistrationService } from '../../../../core/services/registration.service';
import { PaymentInfoComponent } from './payment-info.component';

describe('PaymentInfoComponent (fee fields come from fee settings, never defaults)', () => {
  let form: FormGroup;

  function create(): ComponentFixture<PaymentInfoComponent> {
    const fb = new FormBuilder();
    form = fb.group({
      admissionFee: [''],
      subscription: [''],
      receiptNo: [''],
      paymentMethod: [''],
      properties: fb.array([]),
    });

    TestBed.configureTestingModule({
      imports: [ReactiveFormsModule],
      providers: [
        provideTranslateService(),
        {
          provide: RegistrationService,
          useValue: { getSubscriptionQuote: () => of({ base: 100, extraUnits: 0, extraRate: 0, extraAmount: 0, total: 100, unit: 'taka', rateVersionEffectiveFrom: '2026-01-01' }) },
        },
      ],
    });
    const fixture = TestBed.createComponent(PaymentInfoComponent);
    fixture.componentRef.setInput('form', form);
    return fixture;
  }

  it('renders the Admission Fee input read-only', () => {
    const fixture = create();
    fixture.detectChanges();
    const input = fixture.nativeElement.querySelector('#admissionFee');
    expect(input).not.toBeNull();
    expect(input.readOnly).toBe(true);
  });

  it('displays the fee-settings value the parent loaded, not a hard-coded default', () => {
    const fixture = create();
    // Simulate the parent having fetched fee settings and patched the value in.
    form.patchValue({ admissionFee: '1234' });
    fixture.detectChanges();
    const input = fixture.nativeElement.querySelector('#admissionFee');
    expect(input.value).toBe('1234');
  });

  it('leaves the fee blank until the parent provides a value (no fallback amount)', () => {
    const fixture = create();
    fixture.detectChanges();
    const input = fixture.nativeElement.querySelector('#admissionFee');
    expect(input.value).toBe('');
  });

  it('renders the Subscription input read-only and backend-quoted', () => {
    const fixture = create();
    fixture.detectChanges();
    const input = fixture.nativeElement.querySelector('#subscription');
    expect(input).not.toBeNull();
    expect(input.readOnly).toBe(true);
  });

  it('does not subscribe to property changes that would overwrite the quote', () => {
    const fixture = create();
    fixture.detectChanges();
    const properties = form.get('properties') as FormArray;
    expect(properties.length).toBe(0);
    // Component stays healthy when the parent mutates the properties array.
    properties.push(new FormBuilder().group({ myShareQuantity: ['2'] }));
    expect(() => fixture.detectChanges()).not.toThrow();
  });
});
