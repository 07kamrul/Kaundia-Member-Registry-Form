import { toFileUrl } from './admin.service';

describe('toFileUrl', () => {
  it('returns undefined for a missing path', () => {
    expect(toFileUrl(null)).toBeUndefined();
    expect(toFileUrl('')).toBeUndefined();
  });

  it('keeps ASCII paths readable and under /uploads', () => {
    const url = toFileUrl('photos/member_1/49c37e5259124168a4e9fc5568f19849.jpg');
    expect(url).toMatch(/\/uploads\/photos\/member_1\/49c37e5259124168a4e9fc5568f19849\.jpg$/);
  });

  it('percent-encodes non-ASCII and space-bearing segments', () => {
    const folder = encodeURIComponent('খাজনা-কর রশিদ');
    const url = toFileUrl('documents/member_1/খাজনা-কর রশিদ/0ab8b2a644b84b89984365a713f400ee.pdf');

    expect(url).toContain(
      `/uploads/documents/member_1/${folder}/0ab8b2a644b84b89984365a713f400ee.pdf`,
    );
    // No raw Unicode or whitespace can leak into the request line.
    expect([...url!].every((char) => char.charCodeAt(0) < 128)).toBe(true);
  });

  it('encodes reserved characters in a segment instead of dropping them', () => {
    const url = toFileUrl('documents/member_1/50% discount/notes.pdf');
    expect(url).toContain('/documents/member_1/50%25%20discount/notes.pdf');
  });
});
