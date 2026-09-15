import { Component, OnInit } from '@angular/core';
import { JsonPipe } from '@angular/common';
import { MemberService, type MemberProfile } from '../../../../core/services/member.service';

@Component({
  selector: 'app-member-profile',
  standalone: true,
  imports: [JsonPipe],
  templateUrl: './profile.component.html',
})
export class ProfileComponent implements OnInit {
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
        this.error = 'প্রোফাইল লোড করা যায়নি।';
        this.loading = false;
      },
    });
  }
}
