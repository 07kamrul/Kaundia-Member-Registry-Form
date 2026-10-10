import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { AddressLocationService } from './address-location.service';
import { environment } from '../../../../environments/environment';
import { RegistrationService } from '../../../core/services/registration.service';

describe('AddressLocationService', () => {
  let http: HttpTestingController;
  let service: AddressLocationService;
  const GEO = {
    divisions: [{ id: 'A', name: 'Dhaka', bn_name: 'ঢাকা' }],
    districts: [
      { id: 'D1', division_id: 'A', name: 'Savar', bn_name: 'সাভার' },
      { id: 'D2', division_id: 'B', name: 'Other', bn_name: 'অন্য' },
    ],
    upazilas: [{ district_id: 'D1', name: 'Savar Upazila', bn_name: 'সাভার উপজেলা' }],
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    http = TestBed.inject(HttpTestingController);
    service = TestBed.inject(AddressLocationService);
  });

  it('streams divisions and filters districts by division name (bn or en)', () => {
    let divisions: unknown[] = [];
    service.getDivisions().subscribe((d) => (divisions = d));
    http.expectOne(`${environment.apiBaseUrl}/data/bd-geo.json`).flush(GEO);
    expect(divisions).toEqual([GEO.divisions[0]]);

    let byBnName: unknown[] = ['sentinel'];
    service.getDistrictsByDivisionName('ঢাকা').subscribe((d) => (byBnName = d));
    expect(byBnName).toEqual([GEO.districts[0]]);

    let byEnName: unknown[] = ['sentinel'];
    service.getDistrictsByDivisionName('Dhaka').subscribe((d) => (byEnName = d));
    expect(byEnName).toEqual([GEO.districts[0]]);

    let none: unknown[] = ['sentinel'];
    service.getDistrictsByDivisionName('Nowhere').subscribe((d) => (none = d));
    expect(none).toEqual([]);

    let upazilas: unknown[] = ['sentinel'];
    service.getUpazilasByDistrictName('Savar').subscribe((u) => (upazilas = u));
    expect(upazilas).toEqual([GEO.upazilas[0]]);
  });

  it('caches the geo JSON: later lookups reuse the same request', () => {
    let divisions: unknown[] = [];
    service.getDivisions().subscribe((d) => (divisions = d));
    const req = http.expectOne(`${environment.apiBaseUrl}/data/bd-geo.json`);
    req.flush(GEO);
    expect(divisions).toEqual(GEO.divisions);
    http.verify(); // no second request for a re-subscription
  });
});

describe('RegistrationService', () => {
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

  it('fetches public fee settings as a plain key/value map', () => {
    let fees: unknown;
    service.getPublicFeeSettings().subscribe((f: Record<string, number>) => (fees = f));
    http.expectOne((r) => r.url.endsWith('/public/fee-settings')).flush({
      admission_fee: 500,
    });
    expect(fees).toEqual({ admission_fee: 500 });
  });

  it('quotes the subscription and maps snake_case to camelCase', () => {
    let quote: unknown;
    service.getSubscriptionQuote(3.5).subscribe((q: unknown) => (quote = q));
    const req = http.expectOne((r) =>
      r.url.endsWith('/public/registration/subscription-quote'),
    );
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({ land_size_decimal: 3.5 });
    req.flush({
      base: 100,
      extra_units: 3,
      extra_rate: 10,
      extra_amount: 30,
      total: 130,
      unit: 'taka',
      rate_version_effective_from: '2026-01-01',
    });
    expect(quote).toEqual({
      base: 100,
      extraUnits: 3,
      extraRate: 10,
      extraAmount: 30,
      total: 130,
      unit: 'taka',
      rateVersionEffectiveFrom: '2026-01-01',
    });
  });
});
