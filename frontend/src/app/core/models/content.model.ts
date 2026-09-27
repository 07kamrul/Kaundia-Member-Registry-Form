/**
 * Shared models for the council's published content (notices & events).
 *
 * The API model mirrors the backend JSON exactly (snake_case, numeric ids);
 * the view model is what screens consume (string ids, booleans). Both the
 * management portal (`AdminService`) and the public pages (`ContentService`)
 * map through the same functions so the two sides never drift.
 */

export interface NoticeApiModel {
  id: number;
  title: string;
  body: string;
  category_id: number | null;
  is_published: boolean;
  is_members_only: boolean;
  publish_at: string | null;
  created_by: number | null;
  created_at: string;
  updated_at: string;
}

export interface EventApiModel {
  id: number;
  title: string;
  description: string | null;
  location: string | null;
  category_id: number | null;
  start_at: string;
  end_at: string | null;
  is_published: boolean;
  is_members_only: boolean;
  created_by: number | null;
  created_at: string;
  updated_at: string;
}

export interface Notice {
  id: string;
  title: string;
  body: string;
  categoryId: string | null;
  isPublished: boolean;
  isMembersOnly: boolean;
  publishAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface EventItem {
  id: string;
  title: string;
  description: string | null;
  location: string | null;
  categoryId: string | null;
  startAt: string;
  endAt: string | null;
  isPublished: boolean;
  isMembersOnly: boolean;
  createdAt: string;
  updatedAt: string;
}

export function toNotice(api: NoticeApiModel): Notice {
  return {
    id: String(api.id),
    title: api.title,
    body: api.body,
    categoryId: api.category_id === null ? null : String(api.category_id),
    isPublished: api.is_published,
    isMembersOnly: api.is_members_only,
    publishAt: api.publish_at,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

export function toEventItem(api: EventApiModel): EventItem {
  return {
    id: String(api.id),
    title: api.title,
    description: api.description,
    location: api.location,
    categoryId: api.category_id === null ? null : String(api.category_id),
    startAt: api.start_at,
    endAt: api.end_at,
    isPublished: api.is_published,
    isMembersOnly: api.is_members_only,
    createdAt: api.created_at,
    updatedAt: api.updated_at,
  };
}

/**
 * `datetime-local` value (no offset) -> ISO string in UTC.
 *
 * The value is read as the admin's local wall-clock time and stored as UTC,
 * so every display that formats an ISO instant back into local time shows the
 * same clock face the admin typed.
 */
export function toIso(value: string): string {
  if (!value) return '';
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? '' : parsed.toISOString();
}

/** ISO instant -> `datetime-local` value in the viewer's local timezone. */
export function toDatetimeLocal(value: string | null | undefined): string {
  if (!value) return '';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return '';
  const pad = (part: number): string => String(part).padStart(2, '0');
  return (
    `${parsed.getFullYear()}-${pad(parsed.getMonth() + 1)}-${pad(parsed.getDate())}` +
    `T${pad(parsed.getHours())}:${pad(parsed.getMinutes())}`
  );
}
