/**
 * Visual/layout smoke at multiple viewports + JA/EN toggle.
 * Usage: node scripts/ui-viewport-check.mjs [baseUrl]
 */
import { chromium } from "playwright";
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

const baseUrl = process.argv[2] ?? "http://127.0.0.1:3000";
const host = new URL(baseUrl).hostname;
const outDir = path.join(process.cwd(), ".ui-check");
const widths = [390, 768, 1280];

function overflowNodes(page) {
  return page.evaluate(() => {
    const bad = [];
    for (const el of document.querySelectorAll("body *")) {
      const r = el.getBoundingClientRect();
      if (r.width === 0 && r.height === 0) continue;
      if (r.right > window.innerWidth + 2) {
        const tag = el.tagName.toLowerCase();
        const cls = el.className?.toString?.().slice(0, 60) ?? "";
        bad.push({ tag, cls, right: Math.round(r.right), vw: window.innerWidth });
      }
    }
    return bad.slice(0, 15);
  });
}

async function shot(page, name) {
  await page.screenshot({ path: path.join(outDir, name), fullPage: true });
}

async function dismissAboutDialog(page) {
  const dialog = page.locator("dialog[open]");
  if ((await dialog.count()) === 0) return;
  const closeBtn = page.getByRole("button", { name: /Close|閉じる/i });
  if ((await closeBtn.count()) > 0) {
    await closeBtn.first().click();
  } else {
    await page.keyboard.press("Escape");
  }
  await page.waitForTimeout(200);
}

async function clickLocale(page, code) {
  const pattern =
    code === "ja" ? /^JA$|Switch to Japanese/i : /^EN$|Switch to English/i;
  const btn = page.getByRole("button", { name: pattern });
  if ((await btn.count()) === 0) {
    throw new Error(`Locale button ${code} not found`);
  }
  await btn.first().click();
  await page.waitForLoadState("networkidle");
  await page.waitForTimeout(500);
}

const browser = await chromium.launch({ headless: true });
const report = { baseUrl, widths: {}, errors: [] };

try {
  await mkdir(outDir, { recursive: true });

  for (const width of widths) {
    const context = await browser.newContext({
      viewport: { width, height: 900 },
      locale: "ja-JP",
    });
    const cookieDomains = [host];
    if (host === "127.0.0.1") cookieDomains.push("localhost");
    await context.addCookies(
      cookieDomains.map((domain) => ({
        name: "locale",
        value: "ja",
        domain,
        path: "/",
      })),
    );

    const page = await context.newPage();
    await page.goto(baseUrl, { waitUntil: "networkidle", timeout: 60_000 });
    await dismissAboutDialog(page);

    const toggle = page.locator('[role="group"][aria-label="Language"]');
    if ((await toggle.count()) === 0) {
      report.errors.push(`${width}px: Language toggle missing`);
    }

    let h1Ja = (await page.locator("h1").first().textContent())?.trim() ?? "";
    if (!h1Ja.includes("リサーチ")) {
      try {
        await clickLocale(page, "ja");
        h1Ja = (await page.locator("h1").first().textContent())?.trim() ?? "";
      } catch (e) {
        report.errors.push(`${width}px: JA click failed: ${e.message}`);
      }
    }
    await shot(page, `home-${width}px-ja.png`);

    if (!h1Ja.includes("リサーチ")) {
      report.errors.push(`${width}px: JA h1 expected リサーチ, got "${h1Ja}"`);
    }

    let h1En = h1Ja;
    try {
      await clickLocale(page, "en");
      h1En = (await page.locator("h1").first().textContent())?.trim() ?? "";
    } catch (e) {
      report.errors.push(`${width}px: EN click failed: ${e.message}`);
    }
    await shot(page, `home-${width}px-en.png`);

    const overflow = await overflowNodes(page);
    report.widths[width] = {
      h1Ja,
      h1En,
      toggleVisible: (await toggle.count()) > 0,
      overflowCount: overflow.length,
      overflowSample: overflow,
    };

    if (overflow.length > 0) {
      report.errors.push(
        `${width}px: ${overflow.length} element(s) overflow viewport`,
      );
    }
    if (!h1En.toLowerCase().includes("shopee")) {
      report.errors.push(`${width}px: EN h1 unexpected: "${h1En}"`);
    }

    await context.close();
  }
} finally {
  await browser.close();
}

const outPath = path.join(outDir, "report.json");
await writeFile(outPath, JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
process.exit(report.errors.length > 0 ? 1 : 0);
