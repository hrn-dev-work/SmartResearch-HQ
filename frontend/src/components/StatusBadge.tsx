import type { JobStatus } from "@/lib/types";

const STYLES: Record<JobStatus, string> = {
  PENDING: "bg-slate-100 text-slate-600",
  SCRAPING: "bg-amber-50 text-amber-800",
  SCRAPE_FAILED: "bg-red-50 text-red-700",
  AI_INFERENCE: "bg-violet-50 text-violet-800",
  AI_FAILED: "bg-red-50 text-red-700",
  AWAITING_REVIEW: "bg-sky-50 text-sky-800",
  APPROVED: "bg-emerald-50 text-emerald-800",
  REJECTED: "bg-orange-50 text-orange-800",
  EXPORTED: "bg-emerald-50 text-emerald-800",
};

const LABELS: Partial<Record<JobStatus, string>> = {
  AWAITING_REVIEW: "レビュー待ち",
  AI_INFERENCE: "AI 推論中",
  SCRAPING: "取得中",
};

export function StatusBadge({ status }: { status: JobStatus }) {
  const label = LABELS[status] ?? status.replace(/_/g, " ");
  return (
    <span
      className={`inline-flex rounded-md px-2 py-0.5 text-xs font-medium ${STYLES[status]}`}
    >
      {label}
    </span>
  );
}
