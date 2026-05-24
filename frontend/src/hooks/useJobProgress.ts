import { useEffect, useState } from "react";

import { getResearchJob } from "@/lib/api";
import type { JobStatus, ResearchJob } from "@/lib/types";

const IN_PROGRESS: JobStatus[] = ["PENDING", "SCRAPING", "AI_INFERENCE"];
const POLL_INTERVAL_MS = 2000;

export function isJobInProgress(status: JobStatus): boolean {
  return IN_PROGRESS.includes(status);
}

export function useJobProgress(jobId: string) {
  const [job, setJob] = useState<ResearchJob | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isPolling, setIsPolling] = useState(false);

  useEffect(() => {
    let cancelled = false;
    let timer: ReturnType<typeof setTimeout> | undefined;

    async function poll() {
      try {
        const data = await getResearchJob(jobId);
        if (cancelled) return;
        setJob(data);
        setError(null);
        if (isJobInProgress(data.status)) {
          setIsPolling(true);
          timer = setTimeout(poll, POLL_INTERVAL_MS);
        } else {
          setIsPolling(false);
        }
      } catch (err) {
        if (cancelled) return;
        setError(err instanceof Error ? err.message : "読み込みに失敗しました");
        setIsPolling(false);
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    setLoading(true);
    poll();

    return () => {
      cancelled = true;
      if (timer) clearTimeout(timer);
    };
  }, [jobId]);

  return { job, loading, error, isPolling };
}
