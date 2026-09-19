import { Injectable, signal } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';

export type LanguageCode = 'bn' | 'en';

const LANG_KEY = 'krmf_lang';
const DEFAULT_LANG: LanguageCode = 'bn';

@Injectable({ providedIn: 'root' })
export class LanguageService {
  readonly lang = signal<LanguageCode>(this.readStored());

  constructor(private translate: TranslateService) {
    this.translate.addLangs(['bn', 'en']);
    this.translate.use(this.lang());
  }

  toggle(): void {
    const next: LanguageCode = this.lang() === 'bn' ? 'en' : 'bn';
    this.setLang(next);
  }

  setLang(next: LanguageCode): void {
    this.lang.set(next);
    this.translate.use(next);
    try {
      localStorage.setItem(LANG_KEY, next);
    } catch {
      // localStorage unavailable (private mode) — preference just won't persist.
    }
  }

  private readStored(): LanguageCode {
    try {
      const stored = localStorage.getItem(LANG_KEY);
      if (stored === 'bn' || stored === 'en') return stored;
    } catch {
      // ignore
    }
    return DEFAULT_LANG;
  }
}
