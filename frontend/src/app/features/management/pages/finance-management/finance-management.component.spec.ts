import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { provideTranslateService } from '@ngx-translate/core';
import { of, throwError } from 'rxjs';
import { vi } from 'vitest';
import { AdminService } from '../../../../core/services/admin.service';
import { AuthService } from '../../../../core/services/auth.service';
import { FinanceService } from '../../../../core/services/finance.service';
import { FinanceManagementComponent } from './finance-management.component';

const overview = {
  pendingCount: 2,
  monthIncome: 60000,
  monthExpense: 25000,
  monthNet: 35000,
  balance: 210000,
  recent: [],
};

const ledgerPage = {
  items: [
    {
      id: 7,
      txnDate: '2026-10-05',
      type: 'expense' as const,
      categoryId: 3,
      categoryLabel: 'বিদ্যুৎ বিল',
      amount: 8000,
      description: 'অক্টোবর বিল',
      referenceNo: 'FT-2026-0007',
      attachmentUrl: null,
      status: 'pending' as const,
      approvedByName: null,
      approvedAt: null,
      reversalOfId: null,
      createdAt: '2026-10-05T09:00:00Z',
      createdByName: 'Admin',
    },
  ],
  total: 1,
  totals: { income: 0, expense: 8000, net: -8000 },
};

describe('FinanceManagementComponent', () => {
  function setup() {
    const adminTransactions = vi.fn((_filters: unknown) => of(ledgerPage));
    const overviewFn = vi.fn(() => of(overview));
    const createTransaction = vi.fn(() => of(ledgerPage.items[0]));
    const approveTransaction = vi.fn(() => of(ledgerPage.items[0]));
    const rejectTransaction = vi.fn(() => of(ledgerPage.items[0]));
    const deleteTransaction = vi.fn(() => of(undefined));

    TestBed.configureTestingModule({
      imports: [FinanceManagementComponent],
      providers: [
        provideRouter([]),
        provideTranslateService(),
        {
          provide: FinanceService,
          useValue: {
            adminTransactions,
            overview: overviewFn,
            categories: vi.fn(() =>
              of([
                { id: 1, type: 'income' as const, label: 'চাঁদা', isActive: true },
                { id: 3, type: 'expense' as const, label: 'বিদ্যুৎ বিল', isActive: true },
              ]),
            ),
            createTransaction,
            updateTransaction: vi.fn(() => of(ledgerPage.items[0])),
            uploadAttachment: vi.fn(() => of(ledgerPage.items[0])),
            submitTransaction: vi.fn(() => of(ledgerPage.items[0])),
            approveTransaction,
            rejectTransaction,
            reverseTransaction: vi.fn(() => of(ledgerPage.items[0])),
            deleteTransaction,
            unlinkedPayments: vi.fn(() => of([])),
            publishReportNotice: vi.fn(() => of({ id: 1, title: 'x' })),
          },
        },
        {
          provide: AdminService,
          useValue: { createConfigListItem: vi.fn(() => of({ id: '9', label: 'নতুন খাত' })) },
        },
        {
          provide: AuthService,
          useValue: { hasPermission: () => false },
        },
      ],
    });

    const fixture = TestBed.createComponent(FinanceManagementComponent);
    fixture.detectChanges();
    return {
      fixture,
      adminTransactions,
      overviewFn,
      createTransaction,
      approveTransaction,
      rejectTransaction,
      deleteTransaction,
    };
  }

  it('loads ledger + overview widget on init', () => {
    const { fixture, overviewFn } = setup();
    expect(overviewFn).toHaveBeenCalled();
    expect(fixture.componentInstance.overview?.pendingCount).toBe(2);
    expect(fixture.componentInstance.ledger?.total).toBe(1);
  });

  it('passes status chips through to the admin ledger endpoint', () => {
    const { fixture, adminTransactions } = setup();
    adminTransactions.mockClear();
    fixture.componentInstance.setStatusFilter('pending');
    const call = adminTransactions.mock.calls[0][0] as Record<string, unknown>;
    expect(call['status']).toBe('pending');
  });

  it('blocks save with inline field errors instead of calling the API', () => {
    const { fixture, createTransaction } = setup();
    fixture.componentInstance.openCreateForm();
    fixture.componentInstance.formAmount = null;
    fixture.componentInstance.formDescription = '';
    fixture.componentInstance.formCategoryId = null;
    createTransaction.mockClear();

    fixture.componentInstance.save('pending');
    expect(createTransaction).not.toHaveBeenCalled();
    expect(Object.keys(fixture.componentInstance.formFieldErrors).length).toBeGreaterThan(0);
  });

  it('sends snake_case-mapped payload on create', () => {
    const { fixture, createTransaction } = setup();
    fixture.componentInstance.openCreateForm();
    fixture.componentInstance.formType = 'expense';
    fixture.componentInstance.formDate = '2026-10-06';
    fixture.componentInstance.formCategoryId = 3;
    fixture.componentInstance.formAmount = 1200.5;
    fixture.componentInstance.formDescription = 'নিরাপত্তা বিল';

    fixture.componentInstance.save('pending');
    expect(createTransaction).toHaveBeenCalledWith({
      txnDate: '2026-10-06',
      type: 'expense',
      categoryId: 3,
      amount: 1200.5,
      description: 'নিরাপত্তা বিল',
      referenceNo: null,
      internalNotes: null,
      status: 'pending',
      linkedPaymentType: null,
      linkedPaymentId: null,
    });
  });

  it('requires a reason before rejecting and forwards it to the API', () => {
    const { fixture, rejectTransaction } = setup();
    const txn = ledgerPage.items[0];
    fixture.componentInstance.openAction('reject', txn);

    fixture.componentInstance.confirmAction();
    expect(rejectTransaction).not.toHaveBeenCalled();

    fixture.componentInstance.actionReason = 'রশিদ নেই';
    fixture.componentInstance.confirmAction();
    expect(rejectTransaction).toHaveBeenCalledWith(txn.id, 'রশিদ নেই');
  });

  it('shows the raw server error when two-person control blocks approval', () => {
    const { fixture, approveTransaction } = setup();
    approveTransaction.mockReturnValue(
      throwError(() => ({ error: { detail: 'Two-person control: ...' } })),
    );
    fixture.componentInstance.openAction('approve', ledgerPage.items[0]);
    fixture.componentInstance.confirmAction();

    expect(approveTransaction).toHaveBeenCalled();
    expect(fixture.componentInstance.actionError).toContain('Two-person control');
  });

  it('hides direct edits once the 7-day approved-edit window closes', () => {
    const { fixture } = setup();
    const approvedRecent = {
      ...ledgerPage.items[0],
      status: 'approved' as const,
      approvedAt: '2026-09-01T00:00:00Z', // far beyond 7 days
    };
    expect(fixture.componentInstance.editable(approvedRecent)).toBe(false);

    const freshApproval = { ...approvedRecent, approvedAt: new Date().toISOString() };
    expect(fixture.componentInstance.editable(freshApproval)).toBe(true);
    expect(fixture.componentInstance.editable(ledgerPage.items[0])).toBe(true); // pending
  });
});
