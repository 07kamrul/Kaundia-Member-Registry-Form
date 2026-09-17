import { Component, OnInit } from '@angular/core';
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
  imports: [],
  templateUrl: './profile.component.html',
})
export class ProfileComponent implements OnInit {
  profile: MemberProfile | null = null;
  propertySummaries: string[] = [];
  loading = false;
  error = '';

  constructor(private memberService: MemberService) {}

  ngOnInit(): void {
    this.loading = true;
    this.memberService.getProfile().subscribe({
      next: (data) => {
        this.profile = data;
        this.propertySummaries = (data.properties as ProfileProperty[]).map((property) =>
          [
            `সম্পত্তি ${property.id}`,
            property.property_type?.join('/') ?? '',
            property.khatian_no ? `খতিয়ান ${property.khatian_no}` : '',
            property.land_quantity ? `${property.land_quantity} শতাংশ` : '',
          ]
            .filter(Boolean)
            .join(' · ')
            .replace(' · ', ' — '),
        );
        this.loading = false;
      },
      error: () => {
        this.error = 'প্রোফাইল লোড করা যায়নি।';
        this.loading = false;
      },
    });
  }
}
