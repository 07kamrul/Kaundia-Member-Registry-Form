import { describe, expect, it } from 'vitest';
// Minimal ambient declarations: the project has no @types/node, and this
// spec only needs to read one file at test time (vitest runs in Node).
declare const require: { (id: 'node:fs'): { readFileSync: (p: string, encoding: string) => string }; (id: 'node:path'): { resolve: (...p: string[]) => string } };
declare const process: { cwd(): string };
const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const formsScss = readFileSync(resolve(process.cwd(), 'src/styles/_forms.scss'), 'utf-8');

/**
 * Regression for the checkbox styling bugs: every checkbox in the app takes
 * its look from the global form styles, and the checked state only scales the
 * tick mark — the box itself must keep a visible border and white background
 * in BOTH states. The unit-test DOM never loads the global stylesheet, so
 * this pins the stylesheet source directly.
 */

function rule(selector: string): string {
  const start = formsScss.indexOf(`${selector} {`);
  expect(start, `stylesheet must style ${selector}`).toBeGreaterThan(-1);
  const end = formsScss.indexOf('}', start);
  return formsScss.slice(start, end);
}

describe('global checkbox styles (regression: invisible checkboxes)', () => {
  it('defines opaque white background and solid black border tokens', () => {
    const rootStart = formsScss.indexOf(':root {');
    const rootEnd = formsScss.indexOf('}', rootStart);
    const root = formsScss.slice(rootStart, rootEnd);
    expect(root).toContain('--choice-bg: #fff');
    expect(root).toContain('--choice-border: #000');
  });

  it('styles the unchecked box with a 2px border and the background token', () => {
    const ruleText = rule("input[type='checkbox']");
    expect(ruleText).toContain('appearance: none');
    expect(ruleText).toContain('border: 2px solid var(--choice-border)');
    expect(ruleText).toContain('background: var(--choice-bg)');
    // Non-zero box size: a collapsed box is an invisible one.
    expect(ruleText).toContain('width: 20px');
    expect(ruleText).toContain('height: 20px');
  });

  it('the checked state keeps the same box (only the tick mark is scaled in)', () => {
    // The checked pseudo-element scales the mark; the base box rule above is
    // never overridden by a :checked rule that removes the border/background.
    const checked = rule("input[type='checkbox']:checked::after");
    expect(checked).toContain('transform: scale(1)');
    expect(formsScss).not.toMatch(/input\[type='checkbox'\]:checked[^{]*\{[^}]*border:\s*none/);
    expect(formsScss).not.toMatch(/input\[type='checkbox'\]:checked[^{]*\{[^}]*background:\s*transparent/);
  });
});
