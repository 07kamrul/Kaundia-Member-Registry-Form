import { DatePipe } from '@angular/common';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  HostListener,
  Input,
  OnChanges,
  OnDestroy,
  Output,
  SimpleChanges,
} from '@angular/core';
import { TranslatePipe } from '@ngx-translate/core';
import type { Subscription } from 'rxjs';
import { AdminService } from '../../../../../core/services/admin.service';
import type { MemberProfile } from '../../../../../core/models/admin.model';
import { IconComponent } from '../../../../../shared/icon/icon.component';
import { monthNameKey } from '../../../../../shared/constants/months';

interface AddressParts {
  house?: string;
  road?: string;
  postOffice?: string;
  upazila?: string;
  district?: string;
  division?: string;
}

function joinAddress(a: AddressParts): string {
  return [a.house, a.road, a.postOffice, a.upazila, a.district, a.division]
    .filter((part) => !!part)
    .join(', ');
}

/** Read-only side drawer (full-screen sheet on mobile) with a member's full record. */
@Component({
  selector: 'app-member-detail-drawer',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [DatePipe, TranslatePipe, IconComponent],
  templateUrl: './member-detail-drawer.component.html',
})
export class MemberDetailDrawerComponent implements OnChanges, OnDestroy {
  /** Id of the member to show; null keeps the drawer closed. */
  @Input() memberId: string | null = null;
  @Output() closed = new EventEmitter<void>();
  @Output() manageInstallments = new EventEmitter<string>();

  profile: MemberProfile | null = null;
  loading = false;
  error = false;

  private request: Subscription | null = null;

  constructor(
    private adminService: AdminService,
    private cdr: ChangeDetectorRef,
  ) {}

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['memberId']) this.load();
  }

  ngOnDestroy(): void {
    this.request?.unsubscribe();
  }

  @HostListener('document:keydown.escape')
  onEscape(): void {
    if (this.memberId) this.closed.emit();
  }

  load(): void {
    this.request?.unsubscribe();
    this.profile = null;
    this.error = false;
    if (!this.memberId) {
      this.loading = false;
      return;
    }
    this.loading = true;
    this.request = this.adminService.getMemberProfile(this.memberId).subscribe({
      next: (profile) => {
        this.profile = profile;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = true;
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  onBackdropClick(event: MouseEvent): void {
    if (event.target === event.currentTarget) this.closed.emit();
  }

  monthKey(month: number): string {
    return monthNameKey(month);
  }

  presentAddress(p: MemberProfile): string {
    return joinAddress({
      house: p.currentHouse,
      road: p.currentRoad,
      postOffice: p.currentPostOffice,
      upazila: p.currentUpazila,
      district: p.currentDistrict,
      division: p.currentDivision,
    });
  }

  permanentAddress(p: MemberProfile): string {
    return joinAddress({
      house: p.permanentHouse,
      road: p.permanentRoad,
      postOffice: p.permanentPostOffice,
      upazila: p.permanentUpazila,
      district: p.permanentDistrict,
      division: p.permanentDivision,
    });
  }

  initials(p: MemberProfile): string {
    return p.fullName.trim().charAt(0).toUpperCase();
  }
}
