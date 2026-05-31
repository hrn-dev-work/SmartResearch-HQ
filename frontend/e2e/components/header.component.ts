import type { Locator, Page } from "@playwright/test";
export class HeaderComponent {
  readonly root: Locator;
  constructor(page: Page) { this.root = page.getByRole("banner"); }
}
