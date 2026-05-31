import type { Locator, Page } from "@playwright/test";
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
    if (displayName) await this.page.getByLabel(/表示名|Display name/i).fill(displayName);
    await this.submitButton.click();
    await this.page.waitForURL(/\/review\/[0-9a-f-]{36}$/i, { timeout: 30_000 });
    const match = this.page.url().match(/\/review\/([0-9a-f-]{36})$/i);
    if (!match?.[1]) throw new Error(`Unexpected URL: ${this.page.url()}`);
    return match[1];
  }
}
