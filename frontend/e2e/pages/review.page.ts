import type { Locator, Page } from "@playwright/test";
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
