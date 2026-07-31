"use client";

import { useState } from "react";

import { AboutDemoDialog } from "@/components/AboutDemoDialog";
import { useLocale } from "@/components/LocaleProvider";
import { linkQuietClass } from "@/lib/ui-classes";

export function AboutDemoTrigger() {
  const [open, setOpen] = useState(false);
  const { messages } = useLocale();

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className={`${linkQuietClass} text-xs font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ink/25 focus-visible:ring-offset-2 focus-visible:ring-offset-paper`}
      >
        {messages.header.aboutDemo}
      </button>
      <AboutDemoDialog open={open} onClose={() => setOpen(false)} />
    </>
  );
}
