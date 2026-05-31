import type { DashboardPage } from "../pages/dashboard.page";
import { E2E_SELLER_DISPLAY_NAME, E2E_SHOPEE_SHOP_URL } from "./api";
export async function startResearchFromDashboard(dashboardPage: DashboardPage, options: { navigate?: boolean } = {}): Promise<string> {
  if (options.navigate !== false) await dashboardPage.goto();
  return dashboardPage.startResearchAndGoToReview(E2E_SHOPEE_SHOP_URL, E2E_SELLER_DISPLAY_NAME);
}
