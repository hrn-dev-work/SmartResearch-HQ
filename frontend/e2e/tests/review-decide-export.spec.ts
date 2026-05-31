import { test, expect } from "../fixtures/pages.fixture";
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
