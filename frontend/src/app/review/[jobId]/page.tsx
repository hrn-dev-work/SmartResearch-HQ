"use client";

import Image from "next/image";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";

import { Header } from "@/components/Header";
import { StatusBadge } from "@/components/StatusBadge";
import {
  decideReview,
  exportJob,
  getResearchJob,
  getReviewItems,
} from "@/lib/api";
import type { ResearchJob, ReviewItem } from "@/lib/types";

export default function ReviewPage() {
  const params = useParams();
  const jobId = params.jobId as string;

  return <ReviewPageBody key={jobId} jobId={jobId} />;
}

function ReviewPageBody({ jobId }: { jobId: string }) {
  const [job, setJob] = useState<ResearchJob | null>(null);
  const [items, setItems] = useState<ReviewItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    void (async () => {
      try {
        const [jobData, itemsData] = await Promise.all([
          getResearchJob(jobId),
          getReviewItems(jobId),
        ]);
        if (cancelled) {
          return;
        }
        setJob(jobData);
        setItems(itemsData.items);
      } catch (err) {
        if (!cancelled) {
          setError(
            err instanceof Error ? err.message : "読み込みに失敗しました",
          );
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [jobId]);

  const reload = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [jobData, itemsData] = await Promise.all([
        getResearchJob(jobId),
        getReviewItems(jobId),
      ]);
      setJob(jobData);
      setItems(itemsData.items);
    } catch (err) {
      setError(err instanceof Error ? err.message : "読み込みに失敗しました");
    } finally {
      setLoading(false);
    }
  }, [jobId]);

  async function handleSelect(item: ReviewItem, candidateId: string) {
    await decideReview(item.item_id, candidateId);
    setMessage(`確定: ${item.title}`);
    await reload();
  }

  async function handleReject(item: ReviewItem) {
    await decideReview(item.item_id, null, true);
    setMessage(`却下: ${item.title}`);
    await reload();
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
        {error && (
          <p className="mt-8 border-l-2 border-red-500 pl-3 text-sm text-red-600">
            {error}
          </p>
        )}

        <section className="mt-16">
          {loading ? (
            <p className="text-sm text-slate-500">読み込み中…</p>
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
}: {
  item: ReviewItem;
  onSelect: (candidateId: string) => void;
  onReject: () => void;
}) {
  const decided = item.decision !== null;

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
          {item.candidates.map((c) => (
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
          ))}
        </ul>
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
