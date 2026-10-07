import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { provideTranslateService } from '@ngx-translate/core';
import { of } from 'rxjs';
import { vi } from 'vitest';
import {
  FinanceService,
  formatFinanceAmount,
  formatPercent,
  formatTaka,
  type FinanceSummary,
} from '../../../../core/services/finance.service';
import { FundTransparencyComponent } from './fund-transparency.component';

const summary: FinanceSummary = {
  period: { type: 'month', dateFrom: '2026-10-01', dateTo: '2026-10-08' },
  totals: { income: 50000, expense: 32000, net: 18000 },
  balance: 125000,
  previous: { income: 40000, expense: 20000, net: 20000 },
  incomeByCategory: [
    { categoryId: 1, category: 'চাঁদা', amount: 40000, share: 80 },
    { categoryId: 2, category: 'ভর্তি ফি', amount: 10000, share: 20 },
  ],
  expenseByCategory: [
    { categoryId: 3, category: 'বিদ্যুৎ বিল', amount: 20000, share: 62.5 },
    { categoryId: 4, category: 'অফিস খরচ', amount: 12000, share: 37.5 },
  ],
  previousIncomeByCategory: [],
  previousExpenseByCategory: [{ categoryId: 3, category: 'বিদ্যুৎ বিল', amount: 14000, share: 70 }],
  series: [
    { label: '2026-09', income: 40000, expense: 20000, net: 20000 },
    { label: '2026-10', income: 50000, expense: 32000, net: 18000 },
  ],
  granularity: 'month',
  transactionCount: 9,
  lastUpdated: '2026-10-08T10:00:00+00:00',
};

describe('finance formatting helpers', () => {
  it('formats lakh grouping with Bangla digits in Bangla', () => {
    expect(formatFinanceAmount(1250000.5, 'bn')).toBe('১২,৫০,০০০.৫০');
    expect(formatTaka(50000, 'bn')).toBe('৳ ৫০,০০০.০০');
  });

  it('keeps Western digits in English with the same grouping', () => {
    expect(formatFinanceAmount(1250000.5, 'en')).toBe('12,50,000.50');
    expect(formatTaka(50000, 'en')).toBe('৳ 50,000.00');
  });

  it('formats percentages with one decimal', () => {
    expect(formatPercent(42.31, 'bn')).toBe('৪২.৩%');
    expect(formatPercent(42.31, 'en')).toBe('42.3%');
  });

  it('handles negative amounts and non-finite input', () => {
    expect(formatFinanceAmount(-1250, 'en')).toBe('-1,250.00');
    expect(formatFinanceAmount(Number.NaN, 'en')).toBe('0.00');
  });
});

describe('FundTransparencyComponent', () => {
  function setup() {
    const summaryYear: FinanceSummary = {
      ...summary,
      period: { type: 'year', dateFrom: '2026-01-01', dateTo: '2026-10-08' },
    };
    const getSummary = vi.fn((period: string) => of(period === 'year' ? summaryYear : summary));
    const getTransactions = vi.fn((_filters: unknown) =>
      of({
        items: [],
        total: 0,
        totals: { income: 0, expense: 0, net: 0 },
      }),
    );

    TestBed.configureTestingModule({
      imports: [FundTransparencyComponent],
      providers: [
        provideRouter([]),
        provideTranslateService(),
        { provide: FinanceService, useValue: { getSummary, getTransactions } },
      ],
    });

    const fixture = TestBed.createComponent(FundTransparencyComponent);
    fixture.detectChanges();
    return { fixture, getSummary, getTransactions };
  }

  it('loads the month summary and ledger on init', () => {
    const { fixture, getSummary, getTransactions } = setup();
    expect(getSummary).toHaveBeenCalledWith('month');
    expect(getTransactions).toHaveBeenCalled();
    expect(fixture.componentInstance.summary?.balance).toBe(125000);
  });

  it('computes plain-language deltas against the previous window', () => {
    const { fixture } = setup();
    // income 40000 -> 50000 = +25%
    expect(fixture.componentInstance.incomeDelta).toBe(25);
    // expense 20000 -> 32000 = +60%
    expect(fixture.componentInstance.expenseDelta).toBe(60);
  });

  it('flags expense categories that jumped >= 25% vs the previous window', () => {
    const { fixture } = setup();
    const spikes = fixture.componentInstance.expenseSpikes;
    expect(spikes.length).toBe(1);
    expect(spikes[0].category).toBe('বিদ্যুৎ বিল');
    expect(spikes[0].pct).toBe(43);
  });

  it('re-renders everything when the period changes: the ledger date filter follows the period', () => {
    const { fixture, getSummary, getTransactions } = setup();
    getSummary.mockClear();
    getTransactions.mockClear();

    fixture.componentInstance.setPeriod('year');
    expect(getSummary).toHaveBeenCalledWith('year');
    const call = getTransactions.mock.calls[0][0] as Record<string, unknown>;
    expect(call['dateFrom']).toBe('2026-01-01');
  });

  it('builds and removes active filter chips', () => {
    const { fixture } = setup();
    fixture.componentInstance.typeFilter = 'expense';
    fixture.componentInstance.searchText = 'বিদ্যুৎ';
    expect(fixture.componentInstance.activeChips.map((chip) => chip.key)).toEqual(['type', 'search']);

    fixture.componentInstance.removeChip('type');
    expect(fixture.componentInstance.typeFilter).toBe('');
    fixture.componentInstance.clearAllFilters();
    expect(fixture.componentInstance.searchText).toBe('');
  });

  it('formats ledger amounts with the sign matching the transaction type', () => {
    const { fixture } = setup();
    expect(
      fixture.componentInstance.signedAmount({
        id: 1,
        txnDate: '2026-10-01',
        type: 'income',
        categoryId: 1,
        categoryLabel: 'চাঁদা',
        amount: 50000,
        description: 'x',
        referenceNo: null,
        attachmentUrl: null,
        status: 'approved',
        approvedByName: null,
        approvedAt: null,
        reversalOfId: null,
        createdAt: '2026-10-01T00:00:00Z',
      }),
    ).toBe('+ ৳ ৫০,০০০.০০');
  });
});
