"use client";

import Image from "next/image";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { Header } from "@/components/Header";
import { StatusBadge } from "@/components/StatusBadge";
import { isJobInProgress, useJobProgress } from "@/hooks/useJobProgress";
import {
  decideReview,
  exportJob,
  getReviewItems,
} from "@/lib/api";
import { asinValidationMessage, normalizeAsin } from "@/lib/asin";
import type { ReviewItem } from "@/lib/types";

export default function ReviewPage() {
  const params = useParams();
  const jobId = params.jobId as string;

  return <ReviewPageBody key={jobId} jobId={jobId} />;
}

function ReviewPageBody({ jobId }: { jobId: string }) {
  const [items, setItems] = useState<ReviewItem[]>([]);
  const [itemsLoading, setItemsLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const {
    job,
    loading: jobLoading,
    error: jobError,
    isPolling,
  } = useJobProgress(jobId);

  const displayError = error ?? jobError;

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
          setError(
            err instanceof Error ? err.message : "商品一覧の読み込みに失敗しました",
          );
        }
      } finally {
        if (!cancelled) setItemsLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [job, jobId]);

  const loadItems = useCallback(async () => {
    setItemsLoading(true);
    setError(null);
    try {
      const itemsData = await getReviewItems(jobId);
      setItems(itemsData.items);
    } catch (err) {
      setError(err instanceof Error ? err.message : "商品一覧の読み込みに失敗しました");
    } finally {
      setItemsLoading(false);
    }
  }, [jobId]);

  async function handleSelect(item: ReviewItem, candidateId: string) {
    await decideReview(item.item_id, candidateId);
    setMessage(`確定: ${item.title}`);
    await loadItems();
  }

  async function handleReject(item: ReviewItem) {
    await decideReview(item.item_id, null, true);
    setMessage(`却下: ${item.title}`);
    await loadItems();
  }

  async function handleManualAsin(item: ReviewItem, asin: string) {
    await decideReview(item.item_id, { manualAsin: asin });
    setMessage(`ASIN ${asin} で確定: ${item.title}`);
    await loadItems();
  }

  async function handleExport() {
    setExporting(true);
    try {
      const res = await exportJob(jobId);
      setMessage(
        `${res.exported_count} 件を出力（${res.skipped_count} 件スキップ）`,
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : "出力に失敗しました");
    } finally {
      setExporting(false);
    }
  }

  const sellerLabel =
    job?.seller.display_name ?? job?.seller.shopee_shop_url ?? "";

  return (
    <>
      <Header />
      <main className="mx-auto w-full max-w-3xl flex-1 px-6 py-12">
        <header className="flex flex-wrap items-start justify-between gap-6">
          <div className="space-y-3">
            <Link
              href="/"
              className="text-sm text-slate-500 transition-colors duration-200 hover:text-slate-900"
            >
              ← 戻る
            </Link>
            <div>
              <h1 className="text-2xl font-semibold tracking-tight text-slate-900">
                レビュー
              </h1>
              {job && (
                <p className="mt-2 text-sm text-slate-500">
                  {sellerLabel}
                  {job.item_count > 0 && (
                    <span className="text-slate-400">
                      {" "}
                      · {job.item_count} 件
                    </span>
                  )}
                </p>
              )}
            </div>
          </div>
          {job && (
            <div className="flex flex-wrap items-center gap-3">
              <StatusBadge status={job.status} />
              {isPolling && (
                <span className="text-sm text-slate-500">
                  {job.progress_pct}% — 処理中…
                </span>
              )}
              <button
                type="button"
                onClick={handleExport}
                disabled={exporting}
                className="rounded-md border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-900 transition-all duration-200 hover:border-slate-300 hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2 active:scale-[0.98] disabled:opacity-50"
              >
                {exporting ? "出力中…" : "スプレッドシートへ出力"}
              </button>
            </div>
          )}
        </header>

        {message && (
          <p className="mt-8 border-l-2 border-emerald-500 pl-3 text-sm text-emerald-700">
            {message}
          </p>
        )}
        {displayError && (
          <p className="mt-8 border-l-2 border-red-500 pl-3 text-sm text-red-600">
            {displayError}
          </p>
        )}

        <section className="mt-16">
          {jobLoading || (itemsLoading && !isJobInProgress(job?.status ?? "PENDING")) ? (
            <p className="text-sm text-slate-500">読み込み中…</p>
          ) : job && isJobInProgress(job.status) ? (
            <p className="text-sm text-slate-500">
              リサーチ処理中です（{job.progress_pct}%）。完了すると商品一覧が表示されます。
            </p>
          ) : items.length === 0 ? (
            <p className="text-sm text-slate-500">レビュー対象がありません。</p>
          ) : (
            <ul className="divide-y divide-slate-200">
              {items.map((item) => (
                <li key={item.item_id} className="py-12 first:pt-0">
                  <ReviewItemRow
                    item={item}
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

function ReviewItemRow({
  item,
  onSelect,
  onReject,
  onManualAsin,
}: {
  item: ReviewItem;
  onSelect: (candidateId: string) => void;
  onReject: () => void;
  onManualAsin: (asin: string) => Promise<void>;
}) {
  const decided = item.decision !== null;
  const [manualAsin, setManualAsin] = useState("");
  const [manualError, setManualError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleManualSubmit() {
    const message = asinValidationMessage(manualAsin);
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
      setManualError(err instanceof Error ? err.message : "確定に失敗しました");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <article
      className={`grid gap-10 lg:grid-cols-2 ${decided ? "opacity-60" : ""}`}
    >
      <div>
        <p className="text-xs font-medium uppercase tracking-wider text-slate-500">
          Shopee
        </p>
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
                販売数 {item.sold_count.toLocaleString()}
              </p>
            )}
          </div>
        </div>
      </div>

      <div>
        <p className="text-xs font-medium uppercase tracking-wider text-slate-500">
          Amazon 候補
        </p>
        <ul className="mt-4 space-y-1">
          {item.candidates.length === 0 ? (
            <li className="py-2 text-sm text-slate-500">
              候補がありません。ASIN を入力してください。
            </li>
          ) : (
            item.candidates.map((c) => (
              <li
                key={c.candidate_id}
                className="flex items-center justify-between gap-4 rounded-md py-3 transition-colors duration-200 hover:bg-slate-100/80"
              >
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium text-slate-900">
                    {c.title}
                  </p>
                  <p className="mt-0.5 text-xs text-slate-500">
                    {c.asin} · 一致度 {(c.confidence * 100).toFixed(0)}%
                  </p>
                </div>
                <button
                  type="button"
                  disabled={decided}
                  onClick={() => onSelect(c.candidate_id)}
                  className="shrink-0 rounded-md bg-slate-900 px-3 py-1.5 text-xs font-medium text-white transition-all duration-200 hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2 active:scale-[0.98] disabled:pointer-events-none disabled:opacity-40"
                >
                  選択
                </button>
              </li>
            ))
          )}
        </ul>
        {!decided && (
          <div className="mt-8 border-t border-slate-200 pt-6">
            <label
              htmlFor={`asin-${item.item_id}`}
              className="text-xs font-medium uppercase tracking-wider text-slate-500"
            >
              手動 ASIN
            </label>
            <div className="mt-3 flex flex-wrap items-end gap-3">
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
                className="w-full max-w-xs border-b border-slate-200 bg-transparent py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-slate-400 focus:outline-none"
              />
              <button
                type="button"
                disabled={submitting || manualAsin.length === 0}
                onClick={handleManualSubmit}
                className="rounded-md border border-slate-200 bg-white px-3 py-2 text-xs font-medium text-slate-900 transition-all duration-200 hover:border-slate-300 hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2 active:scale-[0.98] disabled:opacity-40"
              >
                {submitting ? "送信中…" : "この ASIN で確定"}
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
            該当なし — 却下
          </button>
        ) : (
          <p className="mt-4 text-sm text-slate-500">確定済み</p>
        )}
      </div>
    </article>
  );
}
