// Opens the web build in headless Chromium at iPad size and takes screenshots,
// to check the game really starts in a browser.
//   node tools/web_check.mjs http://localhost:8000/ out_dir
import { chromium } from 'playwright';

const [url, outDir] = process.argv.slice(2);
const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 768, height: 1024 }, hasTouch: true, isMobile: true, deviceScaleFactor: 1 });
const problems = [];
page.on('console', (msg) => { if (msg.type() === 'error') problems.push(msg.text()); console.log(`[console.${msg.type()}] ${msg.text()}`); });
page.on('pageerror', (err) => { problems.push(String(err)); console.log(`[pageerror] ${err}`); });
await page.goto(url);
await page.waitForTimeout(25000);
await page.screenshot({ path: `${outDir}/web_ipad_start.png` });
// Tap "Play as Guest" (lower middle of the welcome screen), then wait for home.
await page.touchscreen.tap(384, 790);
await page.waitForTimeout(6000);
await page.screenshot({ path: `${outDir}/web_ipad_after_tap.png` });
await browser.close();
console.log(problems.length ? `PROBLEMS:\n${problems.join('\n')}` : 'No browser errors.');
