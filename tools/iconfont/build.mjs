import SVGIcons2SVGFontStream from 'svgicons2svgfont';
import svg2ttf from 'svg2ttf';
import { createReadStream, createWriteStream, readFileSync, writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';

const dir = path.dirname(fileURLToPath(import.meta.url));
const svgDir = path.join(dir, 'svg');
const outSvg = path.join(dir, 'AnnivIcons.svg');
const outTtf = path.join(dir, '..', '..', 'assets', 'fonts', 'AnnivIcons.ttf');

// PUA-B codepoints — well outside the PUA-A range Material Icons uses, so
// there is zero risk of collision when both fonts' codepoints are stored in
// the same `EventIcons` lookup map.
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
];

const fontStream = new SVGIcons2SVGFontStream({
  fontName: 'AnnivIcons',
  normalize: true,
  fontHeight: 1024,
});

const out = createWriteStream(outSvg);
fontStream.pipe(out).on('finish', () => {
  const ttf = svg2ttf(readFileSync(outSvg, 'utf8'), {});
  writeFileSync(outTtf, Buffer.from(ttf.buffer));
  console.log('wrote', outTtf);
  console.log(icons.map((i) => `${i.name}: 0x${i.codepoint.toString(16)}`).join('\n'));
});

for (const icon of icons) {
  const glyph = createReadStream(path.join(svgDir, `${icon.name}.svg`));
  glyph.metadata = {
    unicode: [String.fromCodePoint(icon.codepoint)],
    name: icon.name,
  };
  fontStream.write(glyph);
}
fontStream.end();
