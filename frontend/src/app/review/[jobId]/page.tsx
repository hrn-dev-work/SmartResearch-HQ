"use client";

import Image from "next/image";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { Header } from "@/components/Header";
import { useLocale } from "@/components/LocaleProvider";
import { StatusBadge } from "@/components/StatusBadge";
import { isJobInProgress, useJobProgress } from "@/hooks/useJobProgress";
import { decideReview, exportJob, getReviewItems } from "@/lib/api";
import { asinValidationMessage, normalizeAsin } from "@/lib/asin";
import { formatMessage } from "@/lib/format-message";
import type { Messages } from "@/lib/messages/types";
import { fieldInputSmClass, pageXClass } from "@/lib/ui-classes";
import type { ReviewItem } from "@/lib/types";

export default function ReviewPage() {
  const params = useParams();
  const jobId = params.jobId as string;

  return <ReviewPageBody key={jobId} jobId={jobId} />;
}

function ReviewPageBody({ jobId }: { jobId: string }) {
  const { messages } = useLocale();
  const t = messages.review;

  const [items, setItems] = useState<ReviewItem[]>([]);
  const [itemsLoading, setItemsLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [exportFeedback, setExportFeedback] = useState<
    | { kind: "success"; exported: number; skipped: number }
    | { kind: "empty" }
    | null
  >(null);
  const [error, setError] = useState<string | null>(null);
  const [exportError, setExportError] = useState<string | null>(null);

  const {
    job,
    loading: jobLoading,
    error: jobError,
    isPolling,
  } = useJobProgress(jobId);

  const displayError = error ?? jobError ?? exportError;

  useEffect(() => {
    if (!job || isJobInProgress(job.status)) return;

    let cancelled = false;

    void (async () => {
      try {
        const itemsData = await getReviewItems(jobId);
        if (cancelled) return;
        setItems(itemsData.items);
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : t.errorLoadItems);
        }
      } finally {
        if (!cancelled) setItemsLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [job, jobId, t.errorLoadItems]);

  const loadItems = useCallback(async () => {
    setItemsLoading(true);
    setError(null);
    try {
      const itemsData = await getReviewItems(jobId);
      setItems(itemsData.items);
    } catch (err) {
      setError(err instanceof Error ? err.message : t.errorLoadItems);
    } finally {
      setItemsLoading(false);
    }
  }, [jobId, t.errorLoadItems]);

  async function handleSelect(item: ReviewItem, candidateId: string) {
    await decideReview(item.item_id, candidateId);
    setMessage(formatMessage(t.confirmed, { title: item.title }));
    await loadItems();
  }

  async function handleReject(item: ReviewItem) {
    await decideReview(item.item_id, null, true);
    setMessage(formatMessage(t.rejected, { title: item.title }));
    await loadItems();
  }

  async function handleManualAsin(item: ReviewItem, asin: string) {
    await decideReview(item.item_id, { manualAsin: asin });
    setMessage(
      formatMessage(t.confirmedAsin, { asin, title: item.title }),
    );
    await loadItems();
  }

  async function handleExport() {
    setExporting(true);
    setExportError(null);
    try {
      const res = await exportJob(jobId);
      if (res.exported_count > 0) {
        setExportFeedback({
          kind: "success",
          exported: res.exported_count,
          skipped: res.skipped_count,
        });
      } else {
        setExportFeedback({ kind: "empty" });
      }
    } catch (err) {
      setExportFeedback(null);
      setExportError(err instanceof Error ? err.message : t.errorExport);
    } finally {
      setExporting(false);
    }
  }

  const sellerLabel =
    job?.seller.display_name ?? job?.seller.shopee_shop_url ?? "";

  return (
    <>
      <Header />
      <main
        className={`mx-auto w-full max-w-3xl flex-1 py-10 sm:py-12 ${pageXClass}`}
      >
        <header className="flex flex-col gap-6 sm:flex-row sm:items-start sm:justify-between">
          <div className="min-w-0 space-y-3">
            <Link
              href="/"
              className="inline-block text-sm text-slate-500 transition-colors duration-200 hover:text-slate-900"
            >
              {t.back}
            </Link>
            <div>
              <h1 className="text-2xl font-semibold tracking-tight text-slate-900">
                {t.title}
              </h1>
              {job && (
                <p className="mt-2 text-pretty text-sm text-slate-500">
                  <span className="break-all">{sellerLabel}</span>
                  {job.item_count > 0 && (
                    <span className="whitespace-nowrap text-slate-400">
                      {" · "}
                      {formatMessage(t.itemCount, {
                        count: job.item_count,
                      })}
                    </span>
                  )}
                </p>
              )}
            </div>
          </div>
          {job && (
            <div className="flex w-full min-w-0 flex-col gap-3 sm:w-auto sm:flex-row sm:flex-wrap sm:items-center sm:justify-end">
              <div className="flex flex-wrap items-center gap-2 sm:gap-3">
                <StatusBadge status={job.status} />
                {isPolling && (
                  <span className="whitespace-nowrap text-sm text-slate-500">
                    {formatMessage(t.processing, { pct: job.progress_pct })}
                  </span>
                )}
              </div>
              <button
                type="button"
                onClick={handleExport}
                disabled={exporting}
                className="w-full rounded-md border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-900 transition-colors duration-200 hover:border-slate-300 hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2 active:scale-[0.98] disabled:opacity-50 sm:w-auto"
              >
                {exporting ? t.exporting : t.export}
              </button>
            </div>
          )}
        </header>

        {exportFeedback && (
          <ExportResultPanel feedback={exportFeedback} review={t} />
        )}

        {message && (
          <p className="mt-8 text-pretty border-l-2 border-emerald-500 pl-3 text-sm text-emerald-700">
            {message}
          </p>
        )}
        {displayError && (
          <p className="mt-8 text-pretty border-l-2 border-red-500 pl-3 text-sm text-red-600">
            {displayError}
          </p>
        )}

        <section className="mt-12 sm:mt-16">
          {jobLoading ||
          (itemsLoading && !isJobInProgress(job?.status ?? "PENDING")) ? (
            <p className="text-sm text-slate-500">{t.loading}</p>
          ) : job && isJobInProgress(job.status) ? (
            <p className="text-sm text-slate-500">
              {formatMessage(t.processingHint, { pct: job.progress_pct })}
            </p>
          ) : items.length === 0 ? (
            <p className="text-sm text-slate-500">{t.empty}</p>
          ) : (
            <ul className="divide-y divide-slate-200">
              {items.map((item) => (
                <li key={item.item_id} className="py-12 first:pt-0">
                  <ReviewItemRow
                    item={item}
                    review={t}
                    asinMsgs={messages.asin}
                    onSelect={(cid) => handleSelect(item, cid)}
                    onReject={() => handleReject(item)}
                    onManualAsin={(asin) => handleManualAsin(item, asin)}
                  />
                </li>
              ))}
            </ul>
          )}
        </section>
      </main>
    </>
  );
}

function ExportResultPanel({
  feedback,
  review: t,
}: {
  feedback:
    | { kind: "success"; exported: number; skipped: number }
    | { kind: "empty" };
  review: Messages["review"];
}) {
  const isSuccess = feedback.kind === "success";

  return (
    <div
      role="status"
      aria-live="polite"
      className={`mt-6 rounded-md border px-4 py-4 sm:mt-8 ${
        isSuccess
          ? "border-emerald-300 bg-emerald-50"
          : "border-amber-300 bg-amber-50"
      }`}
    >
      <p
        className={`text-base font-semibold ${
          isSuccess ? "text-emerald-950" : "text-amber-950"
        }`}
      >
        {isSuccess ? t.exportResultHeading : t.exportResultEmptyHeading}
      </p>
      {isSuccess ? (
        <>
          <p className="mt-2 text-sm text-emerald-900">
            {formatMessage(t.exportResultCounts, {
              exported: feedback.exported,
              skipped: feedback.skipped,
            })}
          </p>
          <p className="mt-3 text-sm leading-relaxed text-emerald-800">
            {t.exportResultPortfolioNote}
          </p>
        </>
      ) : (
        <p className="mt-2 text-sm leading-relaxed text-amber-900">
          {t.exportResultEmptyDetail}
        </p>
      )}
    </div>
  );
}

function ReviewItemRow({
  item,
  review: t,
  asinMsgs,
  onSelect,
  onReject,
  onManualAsin,
}: {
  item: ReviewItem;
  review: Messages["review"];
  asinMsgs: Messages["asin"];
  onSelect: (candidateId: string) => void;
  onReject: () => void;
  onManualAsin: (asin: string) => Promise<void>;
}) {
  const decided = item.decision !== null;
  const [manualAsin, setManualAsin] = useState("");
  const [manualError, setManualError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleManualSubmit() {
    const message = asinValidationMessage(manualAsin, asinMsgs);
    if (message) {
      setManualError(message);
      return;
    }
    setManualError(null);
    setSubmitting(true);
    try {
      await onManualAsin(normalizeAsin(manualAsin));
      setManualAsin("");
    } catch (err) {
      setManualError(
        err instanceof Error ? err.message : t.errorDecide,
      );
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <article
      className={`grid gap-8 sm:gap-10 lg:grid-cols-2 ${decided ? "opacity-60" : ""}`}
    >
      <div>
        <p className="text-xs font-medium text-slate-500">{t.shopee}</p>
        <div className="mt-4 flex gap-4">
          <div className="relative h-24 w-24 shrink-0 overflow-hidden rounded-md bg-slate-100">
            <Image
              src={item.image_url}
              alt={item.title}
              fill
              className="object-cover"
              unoptimized
            />
          </div>
          <div className="min-w-0">
            <h2 className="text-base font-medium leading-snug text-slate-900">
              {item.title}
            </h2>
            {item.sold_count != null && (
              <p className="mt-2 text-sm text-slate-500">
                {formatMessage(t.soldCount, {
                  count: item.sold_count.toLocaleString(),
                })}
              </p>
            )}
            {item.shopee_item_url ? (
              <a
                href={item.shopee_item_url}
                target="_blank"
                rel="noopener noreferrer"
                className="mt-2 inline-block text-sm text-slate-500 underline-offset-2 transition-colors duration-200 hover:text-slate-900 hover:underline"
              >
                {t.openShopee}
              </a>
            ) : null}
          </div>
        </div>
      </div>

      <div>
        <p className="text-xs font-medium text-slate-500">{t.amazonCandidates}</p>
        <ul className="mt-4 space-y-1">
          {item.candidates.length === 0 ? (
            <li className="py-2 text-sm text-slate-500">{t.noCandidates}</li>
          ) : (
            item.candidates.map((c) => (
              <li
                key={c.candidate_id}
                className="flex flex-col gap-3 rounded-md py-3 sm:flex-row sm:items-center sm:justify-between sm:gap-4 sm:hover:bg-slate-100/80"
              >
                <div className="min-w-0 flex-1">
                  <p className="text-pretty text-sm font-medium text-slate-900">
                    {c.title}
                  </p>
                  <p className="mt-0.5 whitespace-nowrap text-xs text-slate-500">
                    {formatMessage(t.confidence, {
                      asin: c.asin,
                      pct: (c.confidence * 100).toFixed(0),
                    })}
                  </p>
                </div>
                <button
                  type="button"
                  disabled={decided}
                  onClick={() => onSelect(c.candidate_id)}
                  className="w-full shrink-0 rounded-md bg-slate-900 px-3 py-2 text-xs font-medium text-white transition-colors duration-200 hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2 active:scale-[0.98] disabled:pointer-events-none disabled:opacity-40 sm:w-auto sm:py-1.5"
                >
                  {t.select}
                </button>
              </li>
            ))
          )}
        </ul>
        {!decided && (
          <div className="mt-8 border-t border-slate-200 pt-6">
            <label
              htmlFor={`asin-${item.item_id}`}
              className="text-xs font-medium text-slate-500"
            >
              {t.manualAsin}
            </label>
            <div className="mt-3 flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-end">
              <input
                id={`asin-${item.item_id}`}
                type="text"
                inputMode="text"
                autoComplete="off"
                maxLength={10}
                value={manualAsin}
                onChange={(e) => {
                  setManualAsin(e.target.value.toUpperCase());
                  setManualError(null);
                }}
                placeholder="B0XXXXXXXXX"
                className={`${fieldInputSmClass} sm:flex-1`}
              />
              <button
                type="button"
                disabled={submitting || manualAsin.length === 0}
                onClick={handleManualSubmit}
                className="w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-xs font-medium text-slate-900 transition-colors duration-200 hover:border-slate-300 hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2 active:scale-[0.98] disabled:opacity-40 sm:w-auto"
              >
                {submitting ? t.submitting : t.confirmAsin}
              </button>
            </div>
            {manualError && (
              <p className="mt-2 text-sm text-red-600">{manualError}</p>
            )}
          </div>
        )}
        {!decided ? (
          <button
            type="button"
            onClick={onReject}
            className="mt-4 text-sm text-slate-500 underline-offset-2 transition-colors duration-200 hover:text-slate-900 hover:underline"
          >
            {t.reject}
          </button>
        ) : (
          <p className="mt-4 text-sm text-slate-500">{t.decided}</p>
        )}
      </div>
    </article>
  );
}
