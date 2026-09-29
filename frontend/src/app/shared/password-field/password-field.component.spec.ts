import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { provideTranslateService } from '@ngx-translate/core';
import { PasswordFieldComponent } from './password-field.component';

@Component({
  standalone: true,
  imports: [ReactiveFormsModule, PasswordFieldComponent],
  template: `<form (submit)="submitted = true"><app-password-field [formControl]="control" /></form>`,
})
class HostComponent {
  control = new FormControl('secret1');
  submitted = false;
}

describe('PasswordFieldComponent', () => {
  function setup() {
    TestBed.configureTestingModule({ imports: [HostComponent], providers: [provideTranslateService()] });
    const fixture = TestBed.createComponent(HostComponent);
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;
    return {
      fixture,
      host: fixture.componentInstance,
      input: () => el.querySelector('input') as HTMLInputElement,
      button: () => el.querySelector('button') as HTMLButtonElement,
    };
  }

  it('is hidden by default and reflects the bound value', () => {
    const { input } = setup();
    expect(input().type).toBe('password');
    expect(input().value).toBe('secret1');
  });

  it('toggles type without changing the value or replacing the input element', () => {
    const { fixture, input, button } = setup();
    const before = input();
    button().click();
    fixture.detectChanges();
    expect(input()).toBe(before);
    expect(input().type).toBe('text');
    expect(input().value).toBe('secret1');
    expect(button().getAttribute('aria-pressed')).toBe('true');
  });

  it('uses a non-submitting button', () => {
    const { fixture, host, button } = setup();
    expect(button().type).toBe('button');
    button().click();
    fixture.detectChanges();
    expect(host.submitted).toBe(false);
  });

  it('writes typed input back to the form control', () => {
    const { host, input } = setup();
    input().value = 'changed9';
    input().dispatchEvent(new Event('input'));
    expect(host.control.value).toBe('changed9');
  });
});
