import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TranslatePipe } from '@ngx-translate/core';
import { IconComponent } from '../../shared/icon/icon.component';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [RouterLink, IconComponent, TranslatePipe],
  templateUrl: './home.component.html',
})
export class HomeComponent {}
