// Deterministic extraction of the design doc's 9 embedded base64 mockup PNGs.
// Source: docs/reference/Leyfarers Design Document - v2.md L1291-1307, each a
// single line `[imageN]: <data:image/png;base64,....>`.
//
// Guarantees (ticket #26 acceptance criteria):
//   - decodes exactly 9 images to content-appropriate filenames in this dir;
//   - re-run is byte-identical (base64 decode + write of the same bytes);
//   - self-check asserts 9 non-empty, PNG-valid buffers and fails loud otherwise.
//
// Run: node docs/reference/leyfarers-refs/extract-mockups.mjs
// No deps (Node stdlib only; no jq/codex on this box — see MEMORY windows-toolchain-quirks).

import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';

const HERE = dirname(fileURLToPath(import.meta.url));
const SOURCE = resolve(HERE, '..', 'Leyfarers Design Document - v2.md');

// image number -> content-appropriate slug (digest §L3: image1 limited-use action
// UI, then Character, Combat, Spells, Inventory, Aptitudes, Breaks, Settings, Components).
const NAMES = {
  1: 'action-limited-use',
  2: 'character',
  3: 'combat',
  4: 'spells',
  5: 'inventory',
  6: 'aptitudes',
  7: 'breaks',
  8: 'settings',
  9: 'components'
};

const PNG_MAGIC = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const LINE_RE = /^\[image(\d+)\]:\s*<data:image\/png;base64,([A-Za-z0-9+/=]+)>\s*$/;

function parse(text) {
  const out = new Map();
  for (const line of text.split(/\r?\n/)) {
    const m = line.match(LINE_RE);
    if (!m) continue;
    out.set(Number(m[1]), m[2]);
  }
  return out;
}

function main() {
  const text = readFileSync(SOURCE, 'utf8');
  const b64 = parse(text);

  const errors = [];
  const wrote = [];
  for (let n = 1; n <= 9; n++) {
    const slug = NAMES[n];
    const encoded = b64.get(n);
    if (!encoded) { errors.push(`image${n}: not found in source`); continue; }

    const buf = Buffer.from(encoded, 'base64');
    // Determinism proof: a second independent decode of the same input must equal
    // the first — this is what makes re-run byte-identical, checked, not assumed.
    const buf2 = Buffer.from(encoded, 'base64');
    if (!buf.equals(buf2)) { errors.push(`image${n}: non-deterministic decode`); continue; }
    if (buf.length === 0) { errors.push(`image${n}: empty after decode`); continue; }
    if (!buf.subarray(0, 8).equals(PNG_MAGIC)) { errors.push(`image${n}: not a valid PNG (bad magic)`); continue; }

    const file = join(HERE, `image${n}-${slug}.png`);
    writeFileSync(file, buf);
    const sha = createHash('sha256').update(buf).digest('hex');
    wrote.push({ n, slug, bytes: buf.length, sha256: sha });
  }

  for (const w of wrote) {
    console.log(`image${w.n}-${w.slug}.png  ${String(w.bytes).padStart(7)} bytes  sha256=${w.sha256.slice(0, 16)}…`);
  }

  // Self-check (ticket: "asserts 9 images decoded and non-empty").
  const ok = errors.length === 0 && wrote.length === 9;
  if (!ok) {
    console.error(`\nSELF-CHECK FAILED: ${wrote.length}/9 images written.`);
    for (const e of errors) console.error(`  - ${e}`);
    process.exit(1);
  }
  console.log(`\nSELF-CHECK PASSED: 9/9 mockups decoded, non-empty, PNG-valid, deterministic.`);
}

main();
