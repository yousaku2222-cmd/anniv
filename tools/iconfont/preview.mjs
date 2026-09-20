import sharp from 'sharp';
import { readdirSync, readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';

const dir = path.dirname(fileURLToPath(import.meta.url));
const svgDir = path.join(dir, 'svg');
const files = readdirSync(svgDir).filter((f) => f.endsWith('.svg')).sort();

const cell = 160;
const cols = 5;
const rows = Math.ceil(files.length / cols);
const pad = 12;

const tiles = await Promise.all(
  files.map(async (f, i) => {
    const svg = readFileSync(path.join(svgDir, f), 'utf8').replace(
      '<path',
      '<path fill="#E85D43"'
    );
    const png = await sharp(Buffer.from(svg))
      .resize(cell - pad * 2, cell - pad * 2, { fit: 'contain' })
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
  create: {
    width: cols * cell,
    height: rows * cell,
    channels: 4,
    background: '#FBF7F0',
  },
})
  .composite(tiles)
  .png()
  .toFile(path.join(dir, 'preview.png'));

console.log('files:', files);
console.log('wrote', path.join(dir, 'preview.png'));
