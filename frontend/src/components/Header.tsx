"use client";

import Link from "next/link";

import { AboutDemoTrigger } from "@/components/AboutDemoTrigger";
import { LocaleToggle } from "@/components/LocaleToggle";
import { useLocale } from "@/components/LocaleProvider";

export function Header() {
  const { messages } = useLocale();

  return (
    <header className="border-b border-slate-200/80 bg-white/80 backdrop-blur-sm">
      <div className="mx-auto flex max-w-3xl items-center justify-between gap-4 px-6 py-4">
        <Link
          href="/"
          className="group flex items-center gap-3 transition-opacity duration-200 hover:opacity-80"
        >
          <span className="flex h-8 w-8 items-center justify-center rounded-md bg-slate-900 text-xs font-semibold tracking-tight text-white transition-transform duration-200 group-hover:scale-[1.02]">
            SR
          </span>
          <span className="text-base font-semibold tracking-tight text-slate-900">
            SmartResearch
          </span>
        </Link>
        <div className="flex items-center gap-3 sm:gap-4">
          <AboutDemoTrigger />
          <LocaleToggle />
          <span className="hidden text-xs font-medium text-slate-500 sm:inline">
            {messages.header.portfolio}
          </span>
        </div>
      </div>
    </header>
  );
}
