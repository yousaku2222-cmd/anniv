// Rasterizes each glyph straight out of the built TTF (not the source SVG),
// so we see exactly what svg2ttf actually baked in — this is how the
// evenodd-hole-collapsing bug in the SVG->TTF conversion got caught without
// needing a phone round-trip.
import * as fontkit from 'fontkit';
import sharp from 'sharp';
import path from 'path';
import { fileURLToPath } from 'url';

const dir = path.dirname(fileURLToPath(import.meta.url));
const font = fontkit.openSync(path.join(dir, '..', '..', 'assets', 'fonts', 'AnnivIcons.ttf'));

const icons = [
  { name: 'rocket', codepoint: 0xf0001 },
  { name: 'sparkle', codepoint: 0xf0002 },
  { name: 'flame', codepoint: 0xf0003 },
  { name: 'smile', codepoint: 0xf0004 },
  { name: 'lantern', codepoint: 0xf0005 },
  { name: 'ticket', codepoint: 0xf0006 },
  { name: 'bolt', codepoint: 0xf0007 },
  { name: 'swirl', codepoint: 0xf0008 },
  { name: 'stars', codepoint: 0xf0009 },
  { name: 'toast', codepoint: 0xf000a },
  { name: '_test_a (same dir)', codepoint: 0xf00fe },
  { name: '_test_b (opp dir)', codepoint: 0xf00ff },
];

const cell = 160;
const cols = 5;
const rows = Math.ceil(icons.length / cols);
const pad = 12;

const tiles = await Promise.all(
  icons.map(async (icon, i) => {
    const glyph = font.glyphForCodePoint(icon.codepoint);
    const svgPath = glyph.path.toSVG();
    const bbox = glyph.path.bbox;
    const w = bbox.maxX - bbox.minX || 1;
    const h = bbox.maxY - bbox.minY || 1;
    // Glyph paths are y-up (font convention); flip to SVG's y-down and set
    // the viewBox to match the flipped bbox instead of hand-computing a
    // translate offset.
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${bbox.minX} ${-bbox.maxY} ${w} ${h}">
      <rect x="${bbox.minX}" y="${-bbox.maxY}" width="${w}" height="${h}" fill="#FBF7F0"/>
      <g transform="scale(1,-1)"><path d="${svgPath}" fill="#E85D43"/></g>
    </svg>`;
    const png = await sharp(Buffer.from(svg))
      .resize(cell - pad * 2, cell - pad * 2, {
        fit: 'contain',
        background: '#FBF7F0',
      })
      .png()
      .toBuffer();
    return {
      input: png,
      left: (i % cols) * cell + pad,
      top: Math.floor(i / cols) * cell + pad,
    };
  })
);

await sharp({
  create: { width: cols * cell, height: rows * cell, channels: 4, background: '#FBF7F0' },
})
  .composite(tiles)
  .png()
  .toFile(path.join(dir, 'verify.png'));

console.log('wrote', path.join(dir, 'verify.png'));
