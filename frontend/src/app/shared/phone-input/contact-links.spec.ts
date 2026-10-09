import { telHref, toAsciiDigits, toInternationalDigits, whatsAppHref } from './contact-links';

const TEL = 'tel:+8801712345678';
const WHATSAPP = 'https://wa.me/8801712345678';

describe('contact links', () => {
  it.each([
    ['legacy national form', '01712345678'],
    ['E.164', '+8801712345678'],
    ['calling code without plus', '8801712345678'],
    ['00 international prefix', '008801712345678'],
    ['Bangla digits', '০১৭১২৩৪৫৬৭৮'],
    ['spaces and dashes', '017-1234 5678'],
    ['padded E.164 with spaces', '  +880 1712-345678 '],
  ])('builds tel: and wa.me links from the %s', (_label, input) => {
    expect(toInternationalDigits(input)).toBe('8801712345678');
    expect(telHref(input)).toBe(TEL);
    expect(whatsAppHref(input)).toBe(WHATSAPP);
  });

  it.each([
    ['null', null],
    ['undefined', undefined],
    ['empty', ''],
    ['whitespace', '   '],
    ['too short', '123'],
    ['letters only', 'not a number'],
    ['a bare plus', '+'],
  ])('returns null for %s input', (_label, input) => {
    expect(toInternationalDigits(input)).toBeNull();
    expect(telHref(input)).toBeNull();
    expect(whatsAppHref(input)).toBeNull();
  });

  it('keeps valid non-Bangladeshi international numbers', () => {
    expect(telHref('+44 20 7946 0958')).toBe('tel:+442079460958');
    expect(whatsAppHref('+44 20 7946 0958')).toBe('https://wa.me/442079460958');
  });

  it('converts Bangla digits to ASCII and leaves everything else alone', () => {
    expect(toAsciiDigits('দাগ ৮৩০/১')).toBe('দাগ 830/1');
  });
});
