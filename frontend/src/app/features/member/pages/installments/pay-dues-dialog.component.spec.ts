import { TestBed } from '@angular/core/testing';
import { provideTranslateService } from '@ngx-translate/core';
import { of, throwError } from 'rxjs';
import { HttpErrorResponse } from '@angular/common/http';
import { vi } from 'vitest';
import {
  InstallmentPaymentService,
  type InstallmentPayment,
  type PayableSummary,
} from '../../../../core/services/installment-payment.service';
import { PayDuesDialogComponent } from './pay-dues-dialog.component';

const summary: PayableSummary = {
  due: [
    { id: 1, year: 2026, month: 7, amount: 200 },
    { id: 2, year: 2026, month: 8, amount: 200 },
    { id: 3, year: 2026, month: 9, amount: 250 },
  ],
  pendingInstallmentIds: [3],
  totalDue: 400,
  accounts: [
    { method: 'bKash', details: '01700000000' },
    { method: 'Bank', details: 'Sonali A/C 1' },
  ],
  payments: [],
};

function setup(submit = vi.fn()) {
  TestBed.configureTestingModule({
    imports: [PayDuesDialogComponent],
    providers: [provideTranslateService(), { provide: InstallmentPaymentService, useValue: { submit } }],
  });
  const fixture = TestBed.createComponent(PayDuesDialogComponent);
  fixture.componentRef.setInput('summary', summary);
  fixture.detectChanges();
  return { component: fixture.componentInstance, submit };
}

describe('PayDuesDialogComponent', () => {
  it('pre-selects every payable month and excludes pending ones', () => {
    const { component } = setup();

    expect(component.payable().map((i) => i.id)).toEqual([1, 2]);
    expect(component.selectedTotal()).toBe(400);
    expect(component.method()).toBe('bKash');
  });

  it('recomputes the total when months are toggled', () => {
    const { component } = setup();

    component.toggle(1);
    expect(component.selectedTotal()).toBe(200);
    component.toggleAll();
    expect(component.allSelected).toBe(true);
    component.toggleAll();
    expect(component.selectedIds().size).toBe(0);
  });

  it('blocks submit until a valid transaction id is entered', () => {
    const { component, submit } = setup();

    component.transactionRef = 'x<';
    component.submit();

    expect(submit).not.toHaveBeenCalled();
    expect(component.refTouched).toBe(true);
  });

  it('submits selected months and emits the created payment', () => {
    const created = { id: 9, status: 'pending' } as InstallmentPayment;
    const { component, submit } = setup(vi.fn(() => of(created)));
    const emitted = vi.fn();
    component.submitted.subscribe(emitted);

    component.transactionRef = 'TRX12345';
    component.submit();

    expect(submit).toHaveBeenCalledWith(
      expect.objectContaining({ installmentIds: [1, 2], method: 'bKash', transactionRef: 'TRX12345' }),
    );
    expect(emitted).toHaveBeenCalledWith(created);
    expect(component.submitting()).toBe(false);
  });

  it('shows the server error message when submit fails', () => {
    const error = new HttpErrorResponse({
      status: 409,
      error: { detail: 'This transaction ID has already been submitted.' },
    });
    const { component } = setup(vi.fn(() => throwError(() => error)));

    component.transactionRef = 'TRX12345';
    component.submit();

    expect(component.error()).toBe('This transaction ID has already been submitted.');
  });

  it('rejects proof files that are not images or PDFs', () => {
    const { component } = setup();
    const file = new File(['x'], 'a.exe', { type: 'application/octet-stream' });

    component.onProofSelected({ target: { files: [file] } } as unknown as Event);

    expect(component.proof).toBeNull();
    expect(component.proofError).not.toBe('');
  });
});
