#!/usr/bin/env node
/**
 * generate-icons.js - Generate app icon PNGs for Jacque-Copy
 *
 * Draws a proper dual-clipboard icon at various sizes using pure Node.js
 * pixel manipulation (no native dependencies). The design:
 *   - Dark rounded background
 *   - Gold clipboard (Clipboard B) in the back/right
 *   - Charcoal clipboard (Clipboard A) in the front/left with gold accent
 *   - Paper lines and "A"/"B" labels
 *
 * On macOS, convert the SVG (icon.svg) for production-quality icons.
 * This script provides a working fallback that's recognizable.
 */

const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

const ASSETS_DIR = path.join(
  __dirname, "..", "Resources", "Assets.xcassets", "AppIcon.appiconset"
);

// ============================================================
// Color palette (Black & Gold theme)
// ============================================================
const COLORS = {
  bgDark:     [10, 10, 12],
  bgMid:      [44, 44, 46],
  charcoal:   [28, 28, 30],
  charcoalLt: [58, 58, 60],
  gold:       [212, 160, 23],
  goldLight:  [240, 208, 96],
  goldDark:   [184, 134, 11],
  white:      [240, 240, 242],
  whiteSub:   [160, 160, 165],
  border:     [85, 85, 87],
  paperLine:  [85, 85, 87],
};

// ============================================================
// Drawing helpers
// ============================================================

function blend(c1, c2, t) {
  return [
    Math.round(c1[0] + (c2[0] - c1[0]) * t),
    Math.round(c1[1] + (c2[1] - c1[1]) * t),
    Math.round(c1[2] + (c2[2] - c1[2]) * t),
  ];
}

function mix(c1, c2, t) {
  return blend(c1, c2, t);
}

/** Linear interpolation */
function lerp(a, b, t) {
  return a + (b - a) * t;
}

/** Smooth step function for anti-aliasing */
function smoothstep(edge0, edge1, x) {
  const t = Math.max(0, Math.min(1, (x - edge0) / (edge1 - edge0)));
  return t * t * (3 - 2 * t);
}

/**
 * Draw a filled rounded rectangle with anti-aliased edges.
 * cx, cy = center; w, h = width/height; r = corner radius
 */
function drawRoundedRect(ctx, cx, cy, w, h, r, colorFn) {
  const halfW = w / 2;
  const halfH = h / 2;
  const left = Math.floor(cx - halfW);
  const top = Math.floor(cy - halfH);
  const right = Math.ceil(cx + halfW);
  const bottom = Math.ceil(cy + halfH);

  for (let y = top; y <= bottom; y++) {
    for (let x = left; x <= right; x++) {
      // Distance from rectangle interior
      let dx = 0, dy = 0;

      if (x < left + r) dx = (left + r) - x;
      else if (x > right - r) dx = x - (right - r);

      if (y < top + r) dy = (top + r) - y;
      else if (y > bottom - r) dy = y - (bottom - r);

      let alpha;
      if (dx <= 0 && dy <= 0) {
        alpha = 1.0; // Fully inside
      } else if (dx > 0 && dy > 0) {
        // Corner region
        const dist = Math.sqrt(dx * dx + dy * dy);
        alpha = 1.0 - smoothstep(r - 1.5, r + 0.5, dist);
      } else {
        // Edge region
        const dist = Math.max(dx, dy);
        alpha = 1.0 - smoothstep(-0.5, 1.5, dist);
      }

      if (alpha > 0) {
        const color = colorFn(x / ctx.width, y / ctx.height);
        const existing = ctx.getPixel(x, y);
        ctx.setPixel(x, y, blend(existing, color, alpha));
      }
    }
  }
}

/**
 * Draw a filled rectangle (no rounding). Faster.
 */
function drawRect(ctx, x1, y1, x2, y2, colorFn) {
  const l = Math.max(0, Math.floor(x1));
  const t = Math.max(0, Math.floor(y1));
  const r = Math.min(ctx.width - 1, Math.ceil(x2));
  const b = Math.min(ctx.height - 1, Math.ceil(y2));

  for (let y = t; y <= b; y++) {
    for (let x = l; x <= r; x++) {
      ctx.setPixel(x, y, colorFn(x / ctx.width, y / ctx.height));
    }
  }
}

/**
 * Draw a horizontal line with anti-aliasing.
 */
function drawHLine(ctx, x1, x2, y, thickness, colorFn) {
  const halfT = thickness / 2;
  const l = Math.max(0, Math.floor(x1));
  const r = Math.min(ctx.width - 1, Math.ceil(x2));
  const y0 = Math.floor(y - halfT);
  const y1 = Math.ceil(y + halfT);

  for (let py = y0; py <= y1; py++) {
    if (py < 0 || py >= ctx.height) continue;
    const edgeDist = Math.abs(py - y) - halfT;
    const alpha = 1.0 - smoothstep(-0.3, 1.0, edgeDist);

    for (let px = l; px <= r; px++) {
      if (px >= 0 && px < ctx.width) {
        const existing = ctx.getPixel(px, py);
        const color = colorFn(px / ctx.width, py / ctx.height);
        ctx.setPixel(px, py, blend(existing, color, alpha));
      }
    }
  }
}

/** Simple pixel buffer wrapper */
function createContext(width, height) {
  const pixels = new Uint8Array(width * height * 3);
  return {
    width, height,
    getPixel(x, y) {
      if (x < 0 || x >= width || y < 0 || y >= height) return [0, 0, 0];
      const i = (y * width + x) * 3;
      return [pixels[i], pixels[i + 1], pixels[i + 2]];
    },
    setPixel(x, y, color) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      const i = (y * width + x) * 3;
      pixels[i] = Math.max(0, Math.min(255, Math.round(color[0])));
      pixels[i + 1] = Math.max(0, Math.min(255, Math.round(color[1])));
      pixels[i + 2] = Math.max(0, Math.min(255, Math.round(color[2])));
    },
    toPNG() {
      // Build raw image data (filter byte + RGB per row)
      const rawData = Buffer.alloc(height * (1 + width * 3));
      for (let y = 0; y < height; y++) {
        const rowOffset = y * (1 + width * 3);
        rawData[rowOffset] = 0; // filter: none
        for (let x = 0; x < width; x++) {
          const i = (y * width + x) * 3;
          rawData[rowOffset + 1 + x * 3] = pixels[i];
          rawData[rowOffset + 2 + x * 3] = pixels[i + 1];
          rawData[rowOffset + 3 + x * 3] = pixels[i + 2];
        }
      }

      // Build PNG
      const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

      const ihdrData = Buffer.alloc(13);
      ihdrData.writeUInt32BE(width, 0);
      ihdrData.writeUInt32BE(height, 4);
      ihdrData[8] = 8;  // bit depth
      ihdrData[9] = 2;  // color type (RGB)
      ihdrData[10] = 0; // compression
      ihdrData[11] = 0; // filter
      ihdrData[12] = 0; // interlace
      const ihdr = makeChunk("IHDR", ihdrData);

      const compressed = zlib.deflateSync(rawData);
      const idat = makeChunk("IDAT", compressed);
      const iend = makeChunk("IEND", Buffer.alloc(0));

      return Buffer.concat([signature, ihdr, idat, iend]);
    }
  };
}

function makeChunk(type, data) {
  const chunk = Buffer.alloc(4 + 4 + data.length + 4);
  chunk.writeUInt32BE(data.length, 0);
  chunk.write(type, 4, "ascii");
  data.copy(chunk, 8);

  // CRC32
  const crcBuf = Buffer.concat([chunk.subarray(4, 8), data]);
  let crc = 0xffffffff;
  for (let i = 0; i < crcBuf.length; i++) {
    crc ^= crcBuf[i];
    for (let j = 0; j < 8; j++) {
      crc = crc & 1 ? (crc >>> 1) ^ 0xedb88320 : crc >>> 1;
    }
  }
  chunk.writeUInt32BE((crc ^ 0xffffffff) >>> 0, 8 + data.length);
  return chunk;
}

// ============================================================
// Icon drawing
// ============================================================

function drawIcon(size) {
  const ctx = createContext(size, size);
  const s = size; // shorthand for proportions
  const margin = s * 0.04;

  // 1. Background - dark rounded square
  drawRoundedRect(
    ctx, s / 2, s / 2,
    s - margin * 2, s - margin * 2,
    s * 0.2,
    (nx, ny) => {
      // Radial gradient from top-center
      const dx = nx - 0.5;
      const dy = ny - 0.4;
      const dist = Math.sqrt(dx * dx + dy * dy) / 0.7;
      return mix(COLORS.bgMid, COLORS.bgDark, Math.min(1, dist));
    }
  );

  // 2. Background border
  drawRoundedRect(
    ctx, s / 2, s / 2,
    s - margin * 2 + 3, s - margin * 2 + 3,
    s * 0.2,
    () => mix(COLORS.border, COLORS.bgDark, 0.5)
  );

  // 3. Clipboard B (Gold) - back/right
  const clipBX = s * 0.56;
  const clipBY = s * 0.35;
  const clipBW = s * 0.36;
  const clipBH = s * 0.48;
  const clipBR = s * 0.04;

  // Clip body
  drawRoundedRect(
    ctx, clipBX, clipBY, clipBW, clipBH, clipBR,
    (nx, ny) => {
      // Vertical gradient for metallic gold
      const t = (ny * s - (clipBY - clipBH / 2)) / clipBH;
      const gold = mix(
        mix(COLORS.goldLight, COLORS.gold, 0.3 + 0.3 * Math.sin(t * Math.PI)),
        COLORS.goldDark,
        t * 0.5
      );
      return gold;
    }
  );

  // Clip top
  const clipBClipW = s * 0.14;
  const clipBClipH = s * 0.07;
  const clipBClipY = clipBY - clipBH / 2 - clipBClipH / 2;
  drawRect(
    ctx,
    clipBX - clipBClipW / 2, clipBClipY,
    clipBX + clipBClipW / 2, clipBClipY + clipBClipH,
    () => COLORS.gold
  );

  // Paper lines on gold clipboard
  const paperLines = [
    { y: clipBY - clipBH * 0.25, w: 0.70 },
    { y: clipBY - clipBH * 0.05, w: 0.60 },
    { y: clipBY + clipBH * 0.15, w: 0.75 },
  ];
  for (const line of paperLines) {
    drawHLine(
      ctx,
      clipBX - clipBW * 0.35, clipBX + clipBW * line.w * 0.35,
      line.y,
      Math.max(1, s * 0.005),
      () => [184, 134, 11, 0.3 * 255]
    );
  }

  // 4. Clipboard A (Charcoal) - front/left
  const clipAX = s * 0.34;
  const clipAY = s * 0.42;
  const clipAW = s * 0.38;
  const clipAH = s * 0.50;
  const clipAR = s * 0.04;

  drawRoundedRect(
    ctx, clipAX, clipAY, clipAW, clipAH, clipAR,
    (nx, ny) => {
      const t = (ny * s - (clipAY - clipAH / 2)) / clipAH;
      return mix(COLORS.charcoalLt, COLORS.charcoal, t * 0.6 + 0.2);
    }
  );

  // Charcoal clip top
  const clipAClipW = s * 0.16;
  const clipAClipH = s * 0.07;
  const clipAClipY = clipAY - clipAH / 2 - clipAClipH / 2;
  drawRect(
    ctx,
    clipAX - clipAClipW / 2, clipAClipY,
    clipAX + clipAClipW / 2, clipAClipY + clipAClipH,
    () => COLORS.charcoalLt
  );

  // Gold accent stripe on left edge of clipboard A
  drawRect(
    ctx,
    clipAX - clipAW / 2 - 1, clipAY - clipAH / 2 + s * 0.02,
    clipAX - clipAW / 2 + s * 0.01, clipAY + clipAH / 2 - s * 0.02,
    () => COLORS.gold
  );

  // Paper lines on charcoal clipboard
  const paperLinesA = [
    { y: clipAY - clipAH * 0.28, w: 0.65 },
    { y: clipAY - clipAH * 0.12, w: 0.55 },
    { y: clipAY + clipAH * 0.04, w: 0.72 },
    { y: clipAY + clipAH * 0.20, w: 0.50 },
    { y: clipAY + clipAH * 0.36, w: 0.68 },
  ];
  for (const line of paperLinesA) {
    drawHLine(
      ctx,
      clipAX - clipAW * 0.33, clipAX + clipAW * line.w * 0.33,
      line.y,
      Math.max(1, s * 0.004),
      () => [85, 85, 87]
    );
  }

  // 5. Gold corner accent dot
  const dotR = s * 0.015;
  const dotX = s * 0.87;
  const dotY = s * 0.78;
  for (let y = Math.floor(dotY - dotR); y <= Math.ceil(dotY + dotR); y++) {
    for (let x = Math.floor(dotX - dotR); x <= Math.ceil(dotX + dotR); x++) {
      const dx = x - dotX, dy = y - dotY;
      const dist = Math.sqrt(dx * dx + dy * dy);
      const alpha = 1.0 - smoothstep(dotR - 0.5, dotR + 0.5, dist);
      if (alpha > 0 && x >= 0 && x < s && y >= 0 && y < s) {
        const existing = ctx.getPixel(x, y);
        ctx.setPixel(x, y, blend(existing, COLORS.gold, alpha * 0.7));
      }
    }
  }

  return ctx.toPNG();
}

// ============================================================
// Main
// ============================================================

console.log("🎨 Generating Jacque-Copy app icons...\n");

const sizes = [16, 32, 128, 256, 512, 1024];

for (const size of sizes) {
  const outputPath = path.join(ASSETS_DIR, `icon-${size}.png`);
  console.log(`  Drawing ${size}x${size}...`);
  const png = drawIcon(size);
  fs.writeFileSync(outputPath, png);
  console.log(`  ✅ icon-${size}.png (${(png.length / 1024).toFixed(1)} KB)`);
}

console.log("\n🎨 All icons generated successfully!");
console.log("\n📋 Design: Dual clipboard (charcoal + gold) on dark background");
console.log("   For production: convert icon.svg on macOS for pixel-perfect results.");
console.log("   SVG source: Resources/Assets.xcassets/AppIcon.appiconset/icon.svg");
