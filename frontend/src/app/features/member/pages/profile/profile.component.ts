import { Component, OnInit } from '@angular/core';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { MemberService, type MemberProfile } from '../../../../core/services/member.service';

interface ProfileProperty {
  id: number;
  property_type?: string[];
  khatian_no?: string | null;
  land_quantity?: string | null;
}

@Component({
  selector: 'app-member-profile',
  standalone: true,
  imports: [TranslatePipe],
  templateUrl: './profile.component.html',
})
export class ProfileComponent implements OnInit {
  profile: MemberProfile | null = null;
  propertySummaries: string[] = [];
  loading = false;
  error = '';

  constructor(
    private memberService: MemberService,
    private translate: TranslateService,
  ) {}

  ngOnInit(): void {
    this.loading = true;
    this.memberService.getProfile().subscribe({
      next: (data) => {
        this.profile = data;
        this.propertySummaries = (data.properties as ProfileProperty[]).map((property) =>
          [
            `${this.translate.instant('member.profile.propertyItemLabel')} ${property.id}`,
            property.property_type?.join('/') ?? '',
            property.khatian_no ? `${this.translate.instant('member.profile.khatianLabel')} ${property.khatian_no}` : '',
            property.land_quantity ? `${property.land_quantity} ${this.translate.instant('member.profile.decimalUnit')}` : '',
          ]
            .filter(Boolean)
            .join(' · ')
            .replace(' · ', ' — '),
        );
        this.loading = false;
      },
      error: () => {
        this.error = this.translate.instant('member.profile.loadError');
        this.loading = false;
      },
    });
  }
}
