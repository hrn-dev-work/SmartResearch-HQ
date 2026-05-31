import type { Locator, Page } from "@playwright/test";
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
