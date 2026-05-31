import type { Page } from "@playwright/test";
export async function setLocaleCookie(page: Page, locale: "ja" | "en", baseURL: string): Promise<void> {
  const { hostname } = new URL(baseURL);
  await page.context().addCookies([{ name: "locale", value: locale, domain: hostname, path: "/", sameSite: "Lax" }]);
}
