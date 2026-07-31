"use client";

import { useLocale } from "@/components/LocaleProvider";
import type { JobStatus } from "@/lib/types";

/** Quiet status marks — ink / rule, not rainbow pills. */
const STYLES: Record<JobStatus, string> = {
  PENDING: "border border-rule bg-paper text-ink-muted",
  SCRAPING: "border border-rule bg-paper text-ink",
  SCRAPE_FAILED: "border border-red-700/40 bg-paper text-red-800",
  AI_INFERENCE: "border border-rule bg-paper text-ink",
  AI_FAILED: "border border-red-700/40 bg-paper text-red-800",
  AWAITING_REVIEW: "bg-ink text-surface",
  APPROVED: "border border-rule bg-paper text-ink",
  REJECTED: "border border-rule bg-paper text-ink-muted",
  EXPORTED: "border border-rule bg-paper text-ink",
};

export function StatusBadge({ status }: { status: JobStatus }) {
  const { messages } = useLocale();
  const label = messages.status[status] ?? status.replace(/_/g, " ");

  return (
    <span
      className={`inline-flex whitespace-nowrap rounded-sm px-2 py-0.5 text-xs font-medium tabular-nums ${STYLES[status]}`}
    >
      {label}
    </span>
  );
}
