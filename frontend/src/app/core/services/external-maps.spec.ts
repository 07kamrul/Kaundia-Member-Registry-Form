import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { environment } from '../../../environments/environment';
import { BdsMapService } from './bds-map.service';
import { RajukMapService } from './rajuk-map.service';

describe('BdsMapService', () => {
  let service: BdsMapService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    service = TestBed.inject(BdsMapService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('fetches the mouza once and shares the response', () => {
    const collection = { type: 'FeatureCollection', features: [] };
    const values: unknown[] = [];
    service.fetchMouza().subscribe((v) => values.push(v));
    service.fetchMouza().subscribe((v) => values.push(v));

    const requests = http.match(
      `${environment.apiBaseUrl}/member/external-maps/bds/mouza`,
    );
    expect(requests.length).toBe(1);
    requests[0].flush(collection);
    expect(values).toEqual([collection, collection]);
  });
});

describe('RajukMapService', () => {
  let service: RajukMapService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting()],
    });
    service = TestBed.inject(RajukMapService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('queries plots with the viewport bbox', () => {
    const collection = { type: 'FeatureCollection', features: [] };
    service.listPlots('90.34,23.72,90.44,23.82').subscribe();
    const req = http.expectOne(
      `${environment.apiBaseUrl}/member/external-maps/rajuk/plots?bbox=90.34,23.72,90.44,23.82`,
    );
    expect(req.request.method).toBe('GET');
    req.flush(collection);
  });
});
