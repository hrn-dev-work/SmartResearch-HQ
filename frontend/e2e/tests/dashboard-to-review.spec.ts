import { test, expect } from "../fixtures/pages.fixture";
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
