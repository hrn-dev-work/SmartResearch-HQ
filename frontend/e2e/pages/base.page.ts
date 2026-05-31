import type { Page } from "@playwright/test";
import { AboutDemoDialogComponent } from "../components/about-demo-dialog.component";

export abstract class BasePage {
  abstract readonly path: string;
  constructor(protected readonly page: Page) {}
  async goto(): Promise<void> {
    await this.page.goto(this.path);
    await new AboutDemoDialogComponent(this.page).closeIfOpen();
  }
}
