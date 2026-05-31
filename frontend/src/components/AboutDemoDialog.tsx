"use client";

import { useEffect, useRef } from "react";

type AboutDemoDialogProps = {
  open: boolean;
  onClose: () => void;
};

export function AboutDemoDialog({ open, onClose }: AboutDemoDialogProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (open && !dialog.open) {
      dialog.showModal();
    } else if (!open && dialog.open) {
      dialog.close();
    }
  }, [open]);

  return (
    <dialog
      ref={dialogRef}
      onClose={onClose}
      className="fixed inset-0 z-50 m-auto w-[min(100%,32rem)] max-h-[min(90vh,36rem)] overflow-y-auto rounded-md border border-slate-200 bg-white p-0 text-slate-900 shadow-none backdrop:bg-slate-900/20 open:flex open:flex-col"
    >
      <div className="border-b border-slate-200 px-6 py-5">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h2 className="text-lg font-semibold tracking-tight text-slate-900">
              このデモについて
            </h2>
            <p className="mt-1 text-sm text-slate-500">
              SmartResearch-HQ — Portfolio モード
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="shrink-0 rounded-md px-2 py-1 text-sm text-slate-500 transition-colors duration-200 hover:bg-slate-100 hover:text-slate-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2"
            aria-label="閉じる"
          >
            閉じる
          </button>
        </div>
      </div>

      <div className="space-y-8 px-6 py-6 text-sm leading-relaxed text-slate-600">
        <section className="space-y-2">
          <h3 className="text-xs font-medium uppercase tracking-wider text-slate-500">
            システムの目的
          </h3>
          <p>
            越境 EC（Shopee 等）における手作業の商品リサーチ・名寄せを、
            <strong className="font-medium text-slate-900">
              スクレイピング + 候補マッチング + Human-in-the-loop
            </strong>
            で支援し、レビュー後にスプレッドシートへ出力する業務効率化システムです。
          </p>
        </section>

        <section className="space-y-2">
          <h3 className="text-xs font-medium uppercase tracking-wider text-slate-500">
            二刀流アーキテクチャ（表 / 裏）
          </h3>
          <p>
            同一コードベースで <strong className="font-medium text-slate-900">Portfolio（表）</strong>
            と <strong className="font-medium text-slate-900">Production（裏）</strong>
            を切り替えます。いま操作しているのは表版です。
          </p>
          <ul className="list-inside list-disc space-y-1 pl-1">
            <li>
              Postgres / Redis 不使用 — インメモリ Mock（
              <code className="text-xs text-slate-800">APP_MODE=portfolio</code>
              ）
            </li>
            <li>固定フィクスチャで E2E デモが完走（インフラコスト・秘密情報リスクを排除）</li>
          </ul>
        </section>

        <section className="space-y-2">
          <h3 className="text-xs font-medium uppercase tracking-wider text-slate-500">
            Production モード（参考）
          </h3>
          <p>実運用版では次が稼働する設計です（本デモでは無効）。</p>
          <ul className="list-inside list-disc space-y-1 pl-1">
            <li>Playwright による Shopee SOLD 商品のスクレイピング</li>
            <li>非同期キュー（Redis + ARQ）によるジョブ処理</li>
            <li>プラガブルな候補マッチング（Amazon PA-API / Gemini 等）</li>
            <li>Google Sheets API による一括エクスポート</li>
          </ul>
        </section>
      </div>
    </dialog>
  );
}
