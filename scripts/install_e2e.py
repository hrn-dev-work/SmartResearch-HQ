#!/usr/bin/env python3
"""Materialize frontend Playwright E2E files on disk (WSL-safe)."""
from __future__ import annotations

import json
import pathlib
import stat

ROOT = pathlib.Path(__file__).resolve().parent.parent


def write(rel: str, text: str, *, exe: bool = False) -> None:
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    if exe:
        mode = path.stat().st_mode
        path.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


FILES: dict[str, str] = {
    "scripts/run-frontend-e2e.sh": """#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_URL="${NEXT_PUBLIC_API_URL:-http://127.0.0.1:8000/api/v1}"
BASE_URL="${PLAYWRIGHT_BASE_URL:-http://127.0.0.1:3000}"
BACKEND_PID=""
API_LOG="${TMPDIR:-/tmp}/srh-e2e-api.log"
cleanup() {
  if [[ -n "$BACKEND_PID" ]] && kill -0 "$BACKEND_PID" 2>/dev/null; then
    kill "$BACKEND_PID" 2>/dev/null || true
    wait "$BACKEND_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
cd "$ROOT/backend"
if [[ ! -d .venv ]]; then python3 -m venv .venv; fi
source .venv/bin/activate
python -m pip install -q -r requirements-dev.txt
APP_MODE=portfolio MATCHING_PROVIDER=amazon_search \\
  uvicorn app.main:app --host 127.0.0.1 --port 8000 >"$API_LOG" 2>&1 &
BACKEND_PID=$!
for i in $(seq 1 45); do
  if curl -sf "${API_URL}/health" | grep -q '"mode":"portfolio"'; then break; fi
  if [[ "$i" -eq 45 ]]; then echo "backend health timeout" >&2; exit 1; fi
  sleep 1
done
cd "$ROOT/frontend"
if [[ "${CI:-}" == "true" ]]; then npx playwright install --with-deps chromium
else npx playwright install chromium; fi
if [[ "${SKIP_FRONTEND_BUILD:-}" != "1" ]]; then
  NEXT_PUBLIC_API_URL="$API_URL" npm run build
fi
export CI=true NEXT_PUBLIC_API_URL="$API_URL" PLAYWRIGHT_BASE_URL="$BASE_URL"
npm run e2e
""",
    "frontend/playwright.config.ts": """import { defineConfig, devices } from "@playwright/test";

const baseURL = process.env.PLAYWRIGHT_BASE_URL ?? "http://127.0.0.1:3000";
const webServerCommand = process.env.CI
  ? "npm run start -- --hostname 127.0.0.1 --port 3000"
  : "npm run dev -- --hostname 127.0.0.1 --port 3000";

export default defineConfig({
  testDir: "./e2e",
  timeout: 60_000,
  expect: { timeout: 10_000 },
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  forbidOnly: !!process.env.CI,
  reporter: process.env.CI
    ? [["github"], ["html", { open: "never" }]]
    : [["list"], ["html", { open: "on-failure" }]],
  use: {
    baseURL,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
    locale: "ja-JP",
    timezoneId: "Asia/Tokyo",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 720 } },
    },
  ],
  webServer: {
    command: webServerCommand,
    url: baseURL,
    reuseExistingServer: !process.env.CI,
    timeout: process.env.CI ? 180_000 : 120_000,
    env: {
      NEXT_PUBLIC_API_URL:
        process.env.NEXT_PUBLIC_API_URL ?? "http://127.0.0.1:8000/api/v1",
    },
  },
});
""",
    "frontend/e2e/pages/base.page.ts": """import type { Page } from "@playwright/test";
import { AboutDemoDialogComponent } from "../components/about-demo-dialog.component";

export abstract class BasePage {
  abstract readonly path: string;
  constructor(protected readonly page: Page) {}
  async goto(): Promise<void> {
    await this.page.goto(this.path);
    await new AboutDemoDialogComponent(this.page).closeIfOpen();
  }
}
""",
    "frontend/e2e/pages/dashboard.page.ts": """import type { Locator, Page } from "@playwright/test";
import { HeaderComponent } from "../components/header.component";
import { BasePage } from "./base.page";

export class DashboardPage extends BasePage {
  readonly path = "/";
  readonly header: HeaderComponent;
  readonly title: Locator;
  readonly shopUrlInput: Locator;
  readonly submitButton: Locator;
  constructor(page: Page) {
    super(page);
    this.header = new HeaderComponent(page);
    this.title = page.getByRole("heading", { name: /Shopee リサーチ|Shopee research/i });
    this.shopUrlInput = page.getByLabel(/Shopee ショップ URL|Shopee shop URL/i);
    this.submitButton = page.getByRole("button", { name: /リサーチを開始|Start research/i });
  }
  async startResearchAndGoToReview(shopUrl: string, displayName?: string): Promise<string> {
    await this.shopUrlInput.fill(shopUrl);
    if (displayName) await page.getByLabel(/表示名|Display name/i).fill(displayName);
    await this.submitButton.click();
    await this.page.waitForURL(/\\/review\\/[0-9a-f-]{36}$/i, { timeout: 30_000 });
    const match = this.page.url().match(/\\/review\\/([0-9a-f-]{36})$/i);
    if (!match?.[1]) throw new Error(`Unexpected URL: ${this.page.url()}`);
    return match[1];
  }
}
""",
    "frontend/e2e/pages/review.page.ts": """import type { Locator, Page } from "@playwright/test";
import { HeaderComponent } from "../components/header.component";
import { BasePage } from "./base.page";

export class ReviewPage extends BasePage {
  readonly header: HeaderComponent;
  readonly title: Locator;
  readonly exportButton: Locator;
  constructor(page: Page, private readonly jobId: string) {
    super(page);
    this.header = new HeaderComponent(page);
    this.title = page.getByRole("heading", { name: /^レビュー$|^Review$/i });
    this.exportButton = page.getByRole("button", {
      name: /スプレッドシートに出力|Export to spreadsheet/i,
    });
  }
  get path(): string { return `/review/${this.jobId}`; }
  static forJob(page: Page, jobId: string) { return new ReviewPage(page, jobId); }
  statusBanner(): Locator { return this.page.locator("p.border-l-2.border-emerald-500"); }
  async expectLoaded(): Promise<void> { await this.title.waitFor({ state: "visible" }); }
  async waitForItemsReady(): Promise<void> {
    await this.page.getByText(/読み込み中|Loading/i).waitFor({ state: "hidden", timeout: 30_000 });
    await this.exportButton.waitFor({ state: "visible" });
    await this.page.getByRole("button", { name: /^選択$|^Select$/ }).first().waitFor({ state: "visible" });
  }
  async selectFirstCandidate(): Promise<void> {
    await this.page.getByRole("button", { name: /^選択$|^Select$/ }).first().click();
  }
  async exportSpreadsheet(): Promise<void> { await this.exportButton.click(); }
  firstItemCard(): Locator { return this.page.locator("article").first(); }
}
""",
    "frontend/e2e/components/about-demo-dialog.component.ts": """import type { Locator, Page } from "@playwright/test";
export class AboutDemoDialogComponent {
  readonly dialog: Locator;
  readonly closeButton: Locator;
  constructor(page: Page) {
    this.dialog = page.locator("dialog[open]");
    this.closeButton = page.getByRole("button", { name: /閉じる|Close/i });
  }
  async closeIfOpen(): Promise<void> {
    if ((await this.dialog.count()) === 0) return;
    await this.closeButton.first().click();
  }
}
""",
    "frontend/e2e/components/header.component.ts": """import type { Locator, Page } from "@playwright/test";
export class HeaderComponent {
  readonly root: Locator;
  constructor(page: Page) { this.root = page.getByRole("banner"); }
}
""",
    "frontend/e2e/utils/api.ts": """import { expect, type APIRequestContext } from "@playwright/test";
export const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://127.0.0.1:8000/api/v1";
export const E2E_SHOPEE_SHOP_URL = "https://shopee.sg/shop/smoke";
export const E2E_SELLER_DISPLAY_NAME = "E2E Playwright";
export async function assertPortfolioApiReady(request: APIRequestContext): Promise<void> {
  const res = await request.get(`${API_BASE}/health`);
  expect(res.ok()).toBeTruthy();
  const body = (await res.json()) as { status?: string; mode?: string };
  expect(body.status).toBe("ok");
  expect(body.mode).toBe("portfolio");
}
""",
    "frontend/e2e/utils/locale.ts": """import type { Page } from "@playwright/test";
export async function setLocaleCookie(page: Page, locale: "ja" | "en", baseURL: string): Promise<void> {
  const { hostname } = new URL(baseURL);
  await page.context().addCookies([{ name: "locale", value: locale, domain: hostname, path: "/", sameSite: "Lax" }]);
}
""",
    "frontend/e2e/utils/flow.ts": """import type { DashboardPage } from "../pages/dashboard.page";
import { E2E_SELLER_DISPLAY_NAME, E2E_SHOPEE_SHOP_URL } from "./api";
export async function startResearchFromDashboard(dashboardPage: DashboardPage, options: { navigate?: boolean } = {}): Promise<string> {
  if (options.navigate !== false) await dashboardPage.goto();
  return dashboardPage.startResearchAndGoToReview(E2E_SHOPEE_SHOP_URL, E2E_SELLER_DISPLAY_NAME);
}
""",
    "frontend/e2e/fixtures/pages.fixture.ts": """import { test as base } from "@playwright/test";
import { DashboardPage } from "../pages/dashboard.page";
import { assertPortfolioApiReady } from "../utils/api";
import { setLocaleCookie } from "../utils/locale";
export const test = base.extend<{ dashboardPage: DashboardPage }>({
  dashboardPage: async ({ page }, use) => { await use(new DashboardPage(page)); },
});
test.beforeAll(async ({ request }) => { await assertPortfolioApiReady(request); });
test.beforeEach(async ({ page, baseURL }) => {
  if (!baseURL) throw new Error("baseURL required");
  await setLocaleCookie(page, "ja", baseURL);
});
export { expect } from "@playwright/test";
""",
    "frontend/e2e/tests/dashboard-to-review.spec.ts": """import { test, expect } from "../fixtures/pages.fixture";
import { ReviewPage } from "../pages/review.page";
import { startResearchFromDashboard } from "../utils/flow";
test("dashboard to review", async ({ page, dashboardPage }) => {
  await dashboardPage.goto();
  const jobId = await startResearchFromDashboard(dashboardPage, { navigate: false });
  await expect(page).toHaveURL(new RegExp(`/review/${jobId}$`));
  const reviewPage = ReviewPage.forJob(page, jobId);
  await reviewPage.expectLoaded();
  await expect(reviewPage.title).toHaveText("レビュー");
});
""",
    "frontend/e2e/tests/review-decide-export.spec.ts": """import { test, expect } from "../fixtures/pages.fixture";
import { ReviewPage } from "../pages/review.page";
import { startResearchFromDashboard } from "../utils/flow";
test("review decide and export", async ({ page, dashboardPage }) => {
  const jobId = await startResearchFromDashboard(dashboardPage);
  const reviewPage = ReviewPage.forJob(page, jobId);
  await reviewPage.waitForItemsReady();
  await reviewPage.selectFirstCandidate();
  await expect(reviewPage.statusBanner()).toContainText(/確定:/);
  await reviewPage.exportSpreadsheet();
  await expect(reviewPage.statusBanner()).toContainText(/件を出力/);
});
""",
    "frontend/e2e/README.md": """# E2E (Playwright)

See `frontend/e2e/README.md` in repo for full docs.

```bash
bash scripts/run-frontend-e2e.sh
npm run e2e
```
""",
}


def patch_package_json() -> None:
    path = ROOT / "frontend/package.json"
    pkg = json.loads(path.read_text(encoding="utf-8"))
    scripts = pkg.setdefault("scripts", {})
    scripts.update(
        {
            "e2e": "playwright test",
            "e2e:ui": "playwright test --ui",
            "e2e:headed": "playwright test --headed",
            "e2e:report": "playwright show-report",
        }
    )
    dev = pkg.setdefault("devDependencies", {})
    dev["@playwright/test"] = "^1.49.0"
    dev.setdefault("playwright", "^1.49.0")
    path.write_text(json.dumps(pkg, indent=2) + "\n", encoding="utf-8")


def patch_gitignore() -> None:
    path = ROOT / "frontend/.gitignore"
    text = path.read_text(encoding="utf-8")
    for line in (
        "/test-results/",
        "/playwright-report/",
        "/blob-report/",
        "/playwright/.cache/",
    ):
        if line not in text:
            text += f"\n{line}\n"
    path.write_text(text, encoding="utf-8")


def patch_ci_check() -> None:
    path = ROOT / "scripts/ci-check.sh"
    text = path.read_text(encoding="utf-8")
    if "run-frontend-e2e.sh" in text:
        return
    old = 'NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1 npm run build\n\necho "CI checks passed."'
    new = """NEXT_PUBLIC_API_URL=http://127.0.0.1:8000/api/v1 npm run build

echo "== frontend e2e =="
for required in scripts/run-frontend-e2e.sh frontend/playwright.config.ts frontend/e2e/tests/dashboard-to-review.spec.ts frontend/e2e/README.md; do
  [[ -f "$ROOT/$required" ]] || { echo "missing $required" >&2; exit 1; }
done
SKIP_FRONTEND_BUILD=1 bash "$ROOT/scripts/run-frontend-e2e.sh"

echo "CI checks passed.\""""
    if old not in text:
        raise SystemExit("ci-check.sh pattern not found")
    path.write_text(text.replace(old, new), encoding="utf-8")


def patch_ci_yml() -> None:
    path = ROOT / ".github/workflows/ci.yml"
    text = path.read_text(encoding="utf-8")
    if "run-frontend-e2e.sh" in text:
        return
    old = """      - name: Production build
        env:
          NEXT_PUBLIC_API_URL: http://localhost:8000/api/v1
        run: npm run build

"""
    new = """      - name: Production build
        env:
          NEXT_PUBLIC_API_URL: http://127.0.0.1:8000/api/v1
        run: npm run build

      - name: E2E (Playwright)
        working-directory: ${{ github.workspace }}
        env:
          SKIP_FRONTEND_BUILD: "1"
          NEXT_PUBLIC_API_URL: http://127.0.0.1:8000/api/v1
          PLAYWRIGHT_BASE_URL: http://127.0.0.1:3000
        run: bash scripts/run-frontend-e2e.sh

      - name: Upload Playwright report on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-report
          path: frontend/playwright-report/
          retention-days: 7

"""
    if old not in text:
        raise SystemExit("ci.yml pattern not found")
    path.write_text(text.replace(old, new), encoding="utf-8")


def main() -> None:
    for rel, content in FILES.items():
        write(rel, content, exe=rel.endswith(".sh"))
    patch_package_json()
    patch_gitignore()
    patch_ci_check()
    patch_ci_yml()
    print(f"installed {len(FILES)} files under {ROOT}")


if __name__ == "__main__":
    main()
