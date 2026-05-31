"use client";

import { useState } from "react";

import { AboutDemoDialog } from "@/components/AboutDemoDialog";

export function AboutDemoTrigger() {
  const [open, setOpen] = useState(false);

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="text-xs font-medium text-slate-500 underline-offset-2 transition-colors duration-200 hover:text-slate-900 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2"
      >
        このデモについて
      </button>
      <AboutDemoDialog open={open} onClose={() => setOpen(false)} />
    </>
  );
}
