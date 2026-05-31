"use client";

import { useLocale } from "@/components/LocaleProvider";
import type { JobStatus } from "@/lib/types";

/** Muted status chips — avoid rainbow SaaS template colors. */
const STYLES: Record<JobStatus, string> = {
  PENDING: "bg-slate-100 text-slate-600",
  SCRAPING: "bg-slate-200 text-slate-800",
  SCRAPE_FAILED: "bg-red-50 text-red-800",
  AI_INFERENCE: "bg-slate-200 text-slate-800",
  AI_FAILED: "bg-red-50 text-red-800",
  AWAITING_REVIEW: "bg-slate-900 text-white",
  APPROVED: "bg-slate-100 text-slate-700",
  REJECTED: "bg-slate-100 text-slate-600",
  EXPORTED: "bg-slate-100 text-slate-700",
};

export function StatusBadge({ status }: { status: JobStatus }) {
  const { messages } = useLocale();
  const label = messages.status[status] ?? status.replace(/_/g, " ");

  return (
    <span
      className={`inline-flex whitespace-nowrap rounded-md px-2 py-0.5 text-xs font-medium ${STYLES[status]}`}
    >
      {label}
    </span>
  );
}
