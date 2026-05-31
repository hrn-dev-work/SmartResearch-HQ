import { test as base } from "@playwright/test";
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
