"use client";

import Link from "next/link";

import { AboutDemoTrigger } from "@/components/AboutDemoTrigger";
import { LocaleToggle } from "@/components/LocaleToggle";
import { pageXClass } from "@/lib/ui-classes";

export function Header() {
  return (
    <header className="border-b border-rule bg-surface">
      <div
        className={`mx-auto flex max-w-3xl items-center justify-between gap-3 py-3 sm:gap-4 sm:py-4 ${pageXClass}`}
      >
        <Link
          href="/"
          className="group flex min-w-0 items-center gap-2.5 transition-opacity duration-200 hover:opacity-80 sm:gap-3"
        >
          <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-sm bg-ink text-xs font-semibold tracking-tight text-surface">
            SR
          </span>
          <span className="truncate text-base font-semibold tracking-tight text-ink">
            SmartResearch
          </span>
        </Link>
        <nav
          className="flex shrink-0 items-center gap-2 sm:gap-3"
          aria-label="Utility"
        >
          <LocaleToggle />
          <AboutDemoTrigger />
        </nav>
      </div>
    </header>
  );
}
