import {
  Component,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  computed,
  inject,
  OnInit,
  signal,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { MemberService } from '../../../../core/services/member.service';
import { RegistrationService } from '../../../../core/services/registration.service';
import type { PicnicPayment, PicnicPaymentAdditionalHead } from '../../../../core/services/member.service';

const MAX_ADDITIONAL_HEADS = 20;
const RELATIONS = ['spouse', 'child', 'guest'] as const;

@Component({
  selector: 'app-member-picnic-payment',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe],
  templateUrl: './picnic-payment.component.html',
})
export class PicnicPaymentComponent implements OnInit {
  readonly relations = RELATIONS;
  readonly maxAdditionalHeads = MAX_ADDITIONAL_HEADS;

  loading = false;
  feeLoading = true;
  feeError = false;
  saving = false;
  error = '';
  success = '';

  additionalHeads = signal(0);
  headPrice = signal<number | null>(null);
  additionalPrice = signal<number | null>(null);

  paymentDate = '';
  receiptNo = '';
  paymentMethod = '';
  labels: PicnicPaymentAdditionalHead[] = [];

  payments: PicnicPayment[] = [];

  private readonly cdr = inject(ChangeDetectorRef);
  private readonly translate = inject(TranslateService);

  private readonly memberService: MemberService;
  private readonly registrationService: RegistrationService;

  readonly breakdown = computed(() => {
    const head = this.headPrice();
    const additional = this.additionalPrice();
    if (head === null || additional === null) return null;
    const count = this.additionalHeads();
    const additionalAmount = additional * count;
    return {
      count,
      headPrice: head,
      additionalPrice: additional,
      additionalAmount,
      total: head + additionalAmount,
    };
  });

  constructor() {
    this.memberService = inject(MemberService);
    this.registrationService = inject(RegistrationService);
  }

  ngOnInit(): void {
    this.paymentDate = new Date().toISOString().slice(0, 10);
    this.loadPayments();
    this.loadRates();
  }

  loadPayments(): void {
    this.loading = true;
    this.memberService.getPicnicPayments().subscribe({
      next: (data) => {
        this.payments = data;
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('member.picnic.loadError');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  retryRates(): void {
    this.feeError = false;
    this.feeLoading = true;
    this.loadRates();
  }

  private loadRates(): void {
    this.registrationService.getPublicFeeSettings().subscribe({
      next: (settings) => {
        const head = settings['picnic_head_fee'];
        const additional = settings['picnic_additional_head_fee'];
        if (Number.isFinite(head) && Number.isFinite(additional)) {
          this.headPrice.set(head);
          this.additionalPrice.set(additional);
        } else {
          this.feeError = true;
        }
        this.feeLoading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.feeError = true;
        this.feeLoading = false;
        this.cdr.markForCheck();
      },
    });
  }

  incrementHeads(): void {
    this.setHeads(this.additionalHeads() + 1);
  }

  decrementHeads(): void {
    this.setHeads(this.additionalHeads() - 1);
  }

  onHeadsInput(value: string): void {
    // Integer-only entry; anything non-numeric snaps back to the clamped value.
    const parsed = Number(value);
    this.setHeads(Number.isFinite(parsed) ? Math.trunc(parsed) : 0);
  }

  setHeads(count: number): void {
    const clamped = Math.min(Math.max(Math.trunc(count) || 0, 0), MAX_ADDITIONAL_HEADS);
    if (clamped === this.additionalHeads()) return;
    this.additionalHeads.set(clamped);
    this.syncLabels(clamped);
    this.cdr.markForCheck();
  }

  private syncLabels(count: number): void {
    while (this.labels.length < count) {
      this.labels.push({ name: '', relation: 'guest' });
    }
    this.labels = this.labels.slice(0, count);
  }

  get canSubmit(): boolean {
    return (
      !this.saving &&
      !this.feeLoading &&
      !this.feeError &&
      !!this.paymentDate &&
      this.labels.every((label) => label.name.trim().length > 0)
    );
  }

  submit(): void {
    if (!this.canSubmit) return;
    this.saving = true;
    this.error = '';
    this.success = '';
    this.memberService.createPicnicPayment({
      additionalHeads: this.additionalHeads(),
      additionalPeople: this.labels.map((label) => ({
        name: label.name.trim(),
        relation: label.relation,
      })),
      paymentDate: this.paymentDate,
      receiptNo: this.receiptNo,
      paymentMethod: this.paymentMethod,
    }).subscribe({
      next: (payment) => {
        this.payments = [payment, ...this.payments];
        this.saving = false;
        this.success = this.translate.instant('member.picnic.saveSuccess', { total: payment.total });
        this.additionalHeads.set(0);
        this.labels = [];
        this.receiptNo = '';
        this.cdr.markForCheck();
      },
      error: (err: unknown) => {
        this.error =
          (err as { error?: { detail?: string } })?.error?.detail ??
          this.translate.instant('member.picnic.saveError');
        this.saving = false;
        this.cdr.markForCheck();
      },
    });
  }
}
