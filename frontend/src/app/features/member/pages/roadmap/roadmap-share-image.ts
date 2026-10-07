import {
  formatRoadmapDate,
  localizeDigits,
  timeframeName,
  timeframeWindow,
  type Roadmap,
  type RoadmapItem,
  type RoadmapTimeframe,
} from '../../../../core/services/roadmap.service';

/**
 * Basic shareable graphic for the members' group: title + three timeframe
 * columns. Drawn on a canvas from the same live payload as the page, so it
 * can never drift from what members see.
 */

const WIDTH = 1600;
const HEIGHT = 1000;
const PAD = 56;
const HEADER_H = 190;
const COL_GAP = 28;
const LINE_H = 30;
const MAX_LINES_PER_ITEM = 2;

const COLORS = {
  bg: '#f3efe3',
  card: '#ffffff',
  green: '#1f3d2a',
  greenSoft: '#2e5138',
  gold: '#c9a34c',
  goldText: '#8a611a',
  maroon: '#8a2f22',
  ink: '#1a2a20',
  inkSoft: '#47564a',
  track: '#e2dbc5',
};

const SERIF = "'Tiro Bangla', 'Hind Siliguri', serif";
const SANS = "'Hind Siliguri', 'Noto Sans Bengali', system-ui, sans-serif";

const LABELS = {
  bn: {
    title: 'আমাদের পরিকল্পনা',
    subtitle: 'আমরা কোথায় আছি, কোথায় যাচ্ছি এবং কীভাবে যাচ্ছি।',
    updated: 'সর্বশেষ আপডেট',
    done: 'সম্পন্ন',
    more: 'আরও',
  },
  en: {
    title: 'Our Roadmap',
    subtitle: 'Where we are, where we are going, and how we get there.',
    updated: 'Last updated',
    done: 'done',
    more: 'more',
  },
} as const;

function wrap(ctx: CanvasRenderingContext2D, text: string, maxWidth: number): string[] {
  const lines: string[] = [];
  let line = '';
  for (const word of text.split(/\s+/)) {
    const candidate = line ? `${line} ${word}` : word;
    if (!line || ctx.measureText(candidate).width <= maxWidth) {
      line = candidate;
    } else {
      lines.push(line);
      line = word;
    }
  }
  if (line) lines.push(line);
  return lines;
}

function clampLines(ctx: CanvasRenderingContext2D, lines: string[], maxWidth: number): string[] {
  if (lines.length <= MAX_LINES_PER_ITEM) return lines;
  const kept = lines.slice(0, MAX_LINES_PER_ITEM);
  let last = `${kept[MAX_LINES_PER_ITEM - 1]}…`;
  while (ctx.measureText(last).width > maxWidth && last.length > 2) last = `${last.slice(0, -2)}…`;
  return [...kept.slice(0, -1), last];
}

function fillRoundRect(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  w: number,
  h: number,
  r: number,
): void {
  ctx.beginPath();
  ctx.roundRect(x, y, w, h, r);
  ctx.fill();
}

function drawMarker(ctx: CanvasRenderingContext2D, item: RoadmapItem, x: number, y: number): void {
  const radius = 9;
  if (item.status === 'done') {
    ctx.fillStyle = COLORS.greenSoft;
    ctx.beginPath();
    ctx.arc(x, y, radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = '#ffffff';
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.moveTo(x - 4, y);
    ctx.lineTo(x - 1, y + 3.5);
    ctx.lineTo(x + 4.5, y - 3.5);
    ctx.stroke();
    return;
  }
  ctx.lineWidth = 3;
  ctx.strokeStyle = item.status === 'in_progress' ? COLORS.gold : COLORS.track;
  ctx.beginPath();
  ctx.arc(x, y, radius, 0, Math.PI * 2);
  ctx.stroke();
  if (item.status === 'in_progress') {
    ctx.fillStyle = COLORS.gold;
    ctx.beginPath();
    ctx.arc(x, y, 4, 0, Math.PI * 2);
    ctx.fill();
  }
}

function drawColumnHeader(
  ctx: CanvasRenderingContext2D,
  tf: RoadmapTimeframe,
  left: number,
  top: number,
  width: number,
  lang: 'bn' | 'en',
): number {
  ctx.fillStyle = COLORS.maroon;
  ctx.font = `700 30px ${SERIF}`;
  ctx.fillText(timeframeWindow(tf, lang), left, top + 52);
  ctx.fillStyle = COLORS.inkSoft;
  ctx.font = `500 20px ${SANS}`;
  ctx.fillText(timeframeName(tf, lang), left, top + 82);

  const barY = top + 104;
  ctx.fillStyle = COLORS.track;
  fillRoundRect(ctx, left, barY, width, 12, 6);
  if (tf.percent > 0) {
    ctx.fillStyle = COLORS.greenSoft;
    fillRoundRect(ctx, left, barY, (width * tf.percent) / 100, 12, 6);
  }
  ctx.fillStyle = COLORS.green;
  ctx.font = `700 20px ${SANS}`;
  const done = localizeDigits(tf.done, lang);
  const total = localizeDigits(tf.total, lang);
  const pct = localizeDigits(tf.percent, lang);
  ctx.fillText(`${done}/${total} ${LABELS[lang].done} — ${pct}%`, left, barY + 42);
  return barY + 88;
}

function drawColumn(
  ctx: CanvasRenderingContext2D,
  tf: RoadmapTimeframe,
  x: number,
  width: number,
  lang: 'bn' | 'en',
): void {
  const top = HEADER_H + 40;
  const bottom = HEIGHT - PAD;
  ctx.fillStyle = COLORS.card;
  fillRoundRect(ctx, x, top, width, bottom - top, 18);

  const inner = x + 26;
  const innerW = width - 52;
  let y = drawColumnHeader(ctx, tf, inner, top, innerW, lang);

  ctx.font = `500 21px ${SANS}`;
  const textX = inner + 30;
  const textW = innerW - 30;
  const listBottom = bottom - 40;
  let drawn = 0;
  for (const item of tf.items) {
    const lines = clampLines(ctx, wrap(ctx, item.text, textW), textW);
    if (y + lines.length * LINE_H > listBottom) break;
    drawMarker(ctx, item, inner + 9, y - 7);
    ctx.font = `500 21px ${SANS}`;
    ctx.fillStyle = item.status === 'done' ? COLORS.inkSoft : COLORS.ink;
    lines.forEach((line, i) => ctx.fillText(line, textX, y + i * LINE_H));
    y += lines.length * LINE_H + 14;
    drawn++;
  }
  const remaining = tf.items.length - drawn;
  if (remaining > 0) {
    ctx.fillStyle = COLORS.goldText;
    ctx.font = `600 19px ${SANS}`;
    ctx.fillText(`+ ${localizeDigits(remaining, lang)} ${LABELS[lang].more}`, textX, listBottom + 18);
  }
}

function drawHeader(ctx: CanvasRenderingContext2D, roadmap: Roadmap, lang: 'bn' | 'en'): void {
  const labels = LABELS[lang];
  ctx.fillStyle = COLORS.green;
  ctx.fillRect(0, 0, WIDTH, HEADER_H);
  ctx.fillStyle = COLORS.gold;
  ctx.fillRect(0, HEADER_H, WIDTH, 6);

  ctx.fillStyle = '#ffffff';
  ctx.font = `700 56px ${SERIF}`;
  ctx.fillText(labels.title, PAD, 88);
  ctx.fillStyle = COLORS.gold;
  ctx.font = `500 26px ${SANS}`;
  ctx.fillText(labels.subtitle, PAD, 136);

  ctx.textAlign = 'right';
  ctx.fillStyle = '#ffffff';
  ctx.font = `700 64px ${SERIF}`;
  ctx.fillText(`${localizeDigits(roadmap.totals.percent, lang)}%`, WIDTH - PAD, 96);
  if (roadmap.lastUpdated) {
    ctx.fillStyle = '#d8cfb2';
    ctx.font = `500 20px ${SANS}`;
    ctx.fillText(`${labels.updated}: ${formatRoadmapDate(roadmap.lastUpdated, lang)}`, WIDTH - PAD, 136);
  }
  ctx.textAlign = 'left';
}

export async function renderRoadmapShareImage(roadmap: Roadmap, langCode: string): Promise<Blob> {
  const lang: 'bn' | 'en' = langCode === 'bn' ? 'bn' : 'en';
  // Bangla glyphs need the web fonts loaded before drawing.
  await document.fonts?.ready;

  const canvas = document.createElement('canvas');
  canvas.width = WIDTH;
  canvas.height = HEIGHT;
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('Canvas 2D context unavailable');

  ctx.fillStyle = COLORS.bg;
  ctx.fillRect(0, 0, WIDTH, HEIGHT);
  drawHeader(ctx, roadmap, lang);

  const columns = Math.max(roadmap.timeframes.length, 1);
  const colW = (WIDTH - PAD * 2 - COL_GAP * (columns - 1)) / columns;
  roadmap.timeframes.forEach((tf, i) => drawColumn(ctx, tf, PAD + i * (colW + COL_GAP), colW, lang));

  return new Promise<Blob>((resolve, reject) =>
    canvas.toBlob(
      (blob) => (blob ? resolve(blob) : reject(new Error('PNG encoding failed'))),
      'image/png',
    ),
  );
}
