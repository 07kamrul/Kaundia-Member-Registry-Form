import { Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { MemberService, type MemberProfile } from '../../../../core/services/member.service';
import { IconComponent } from '../../../../shared/icon/icon.component';

@Component({
  selector: 'app-member-dashboard',
  standalone: true,
  imports: [RouterLink, IconComponent],
  templateUrl: './member-dashboard.component.html',
})
export class MemberDashboardComponent implements OnInit {
  profile: MemberProfile | null = null;
  loading = false;
  error = '';

  constructor(private memberService: MemberService) {}

  ngOnInit(): void {
    this.loading = true;
    this.memberService.getProfile().subscribe({
      next: (data) => {
        this.profile = data;
        this.loading = false;
      },
      error: () => {
        this.error = 'তথ্য লোড করা যায়নি।';
        this.loading = false;
      },
    });
  }
}
