import { AsyncPipe } from '@angular/common';
import { Component, DestroyRef, inject, Input, OnInit } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormControl, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { BehaviorSubject, Observable, switchMap } from 'rxjs';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import {
  AddressLocationService,
  District,
  Division,
  Upazila,
} from '../../services/address-location.service';

const ADDRESS_FIELD_ERROR_KEYS: Record<string, string> = {
  division: 'registration.addressInfo.divisionRequired',
  district: 'registration.addressInfo.districtRequired',
  upazila: 'registration.addressInfo.upazilaRequired',
  postOffice: 'registration.addressInfo.postOfficeRequired',
  road: 'registration.addressInfo.roadRequired',
  house: 'registration.addressInfo.houseRequired',
};

@Component({
  selector: 'app-address-info',
  standalone: true,
  imports: [ReactiveFormsModule, AsyncPipe, TranslatePipe],
  templateUrl: './address-info.component.html',
})
export class AddressInfoComponent implements OnInit {
  @Input({ required: true }) form!: FormGroup;
  @Input() submitAttempted = false;

  private readonly destroyRef = inject(DestroyRef);
  private readonly addressLocationService = inject(AddressLocationService);
  private readonly translate = inject(TranslateService);

  sameAsCurrentAddress = new FormControl(false);

  divisions$: Observable<Division[]> = this.addressLocationService.getDivisions();

  private readonly currentDivision$ = new BehaviorSubject<string>('');
  private readonly permanentDivision$ = new BehaviorSubject<string>('');
  private readonly currentDistrict$ = new BehaviorSubject<string>('');
  private readonly permanentDistrict$ = new BehaviorSubject<string>('');

  currentDistricts$: Observable<District[]> = this.currentDivision$.pipe(
    switchMap((divisionName) =>
      this.addressLocationService.getDistrictsByDivisionName(divisionName),
    ),
  );

  permanentDistricts$: Observable<District[]> = this.permanentDivision$.pipe(
    switchMap((divisionName) =>
      this.addressLocationService.getDistrictsByDivisionName(divisionName),
    ),
  );

  currentUpazilas$: Observable<Upazila[]> = this.currentDistrict$.pipe(
    switchMap((districtName) =>
      this.addressLocationService.getUpazilasByDistrictName(districtName),
    ),
  );

  permanentUpazilas$: Observable<Upazila[]> = this.permanentDistrict$.pipe(
    switchMap((districtName) =>
      this.addressLocationService.getUpazilasByDistrictName(districtName),
    ),
  );

  ngOnInit(): void {
    this.sameAsCurrentAddress.valueChanges
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((isSame) => this.applySameAsCurrentAddress(isSame ?? false));

    this.currentAddressGroup.valueChanges
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(() => {
        if (this.sameAsCurrentAddress.value) {
          this.copyCurrentAddressToPermanent();
        }
      });

    this.currentAddressGroup
      .get('division')!
      .valueChanges.pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((division) => this.onDivisionChange('currentAddress', division ?? ''));

    this.permanentAddressGroup
      .get('division')!
      .valueChanges.pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((division) => this.onDivisionChange('permanentAddress', division ?? ''));

    this.currentAddressGroup
      .get('district')!
      .valueChanges.pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((district) => this.onDistrictChange('currentAddress', district ?? ''));

    this.permanentAddressGroup
      .get('district')!
      .valueChanges.pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((district) => this.onDistrictChange('permanentAddress', district ?? ''));
  }

  private onDivisionChange(
    groupName: 'currentAddress' | 'permanentAddress',
    divisionName: string,
  ): void {
    const subject =
      groupName === 'currentAddress' ? this.currentDivision$ : this.permanentDivision$;
    if (subject.value === divisionName) {
      return;
    }
    subject.next(divisionName);
    this.form.get(`${groupName}.district`)?.setValue('', { emitEvent: true });
  }

  private onDistrictChange(
    groupName: 'currentAddress' | 'permanentAddress',
    districtName: string,
  ): void {
    const subject =
      groupName === 'currentAddress' ? this.currentDistrict$ : this.permanentDistrict$;
    if (subject.value === districtName) {
      return;
    }
    subject.next(districtName);
    this.form.get(`${groupName}.upazila`)?.setValue('', { emitEvent: false });
  }

  private get currentAddressGroup(): FormGroup {
    return this.form.get('currentAddress') as FormGroup;
  }

  private get permanentAddressGroup(): FormGroup {
    return this.form.get('permanentAddress') as FormGroup;
  }

  private applySameAsCurrentAddress(isSame: boolean): void {
    if (isSame) {
      this.copyCurrentAddressToPermanent();
      this.permanentAddressGroup.disable({ emitEvent: false });
    } else {
      this.permanentAddressGroup.enable({ emitEvent: false });
    }
  }

  private copyCurrentAddressToPermanent(): void {
    const currentValue = this.currentAddressGroup.value;
    this.permanentDivision$.next(currentValue.division ?? '');
    this.permanentDistrict$.next(currentValue.district ?? '');
    this.permanentAddressGroup.patchValue(currentValue, { emitEvent: false });
  }

  showError(groupName: 'currentAddress' | 'permanentAddress', controlName: string): boolean {
    const control = this.form.get(`${groupName}.${controlName}`);
    return !!control && control.invalid && (control.touched || this.submitAttempted);
  }

  errorMessage(controlName: string): string {
    const key = ADDRESS_FIELD_ERROR_KEYS[controlName];
    return key ? this.translate.instant(key) : '';
  }

  localizedName(item: { name: string; bn_name: string }): string {
    return this.translate.currentLang === 'bn' ? item.bn_name : item.name;
  }
}
