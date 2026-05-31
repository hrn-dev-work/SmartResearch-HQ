import { expect, type APIRequestContext } from "@playwright/test";
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
