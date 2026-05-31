"use client";

import { useEffect, useRef } from "react";

import { useLocale } from "@/components/LocaleProvider";

type AboutDemoDialogProps = {
  open: boolean;
  onClose: () => void;
};

export function AboutDemoDialog({ open, onClose }: AboutDemoDialogProps) {
  const { messages } = useLocale();
  const t = messages.about;
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
              {t.title}
            </h2>
            <p className="mt-1 text-sm text-slate-500">{t.subtitle}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="shrink-0 rounded-md px-2 py-1 text-sm text-slate-500 transition-colors duration-200 hover:bg-slate-100 hover:text-slate-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2"
            aria-label={t.close}
          >
            {t.close}
          </button>
        </div>
      </div>

      <div className="space-y-8 px-6 py-6 text-sm leading-relaxed text-slate-600">
        <section className="space-y-2">
          <h3 className="text-xs font-medium uppercase tracking-wider text-slate-500">
            {t.purposeHeading}
          </h3>
          <p>
            {t.purposeBodyBefore}
            <strong className="font-medium text-slate-900">{t.purposeEmphasis}</strong>
            {t.purposeBodyAfter}
          </p>
        </section>

        <section className="space-y-2">
          <h3 className="text-xs font-medium uppercase tracking-wider text-slate-500">
            {t.archHeading}
          </h3>
          <p>
            {t.archIntroBefore}
            <strong className="font-medium text-slate-900">{t.archPortfolio}</strong>
            {t.archIntroMid}
            <strong className="font-medium text-slate-900">{t.archProduction}</strong>
            {t.archIntroAfter}
          </p>
          <ul className="list-inside list-disc space-y-1 pl-1">
            <li>{t.archBulletMock}</li>
            <li>{t.archBulletFixture}</li>
          </ul>
        </section>

        <section className="space-y-2">
          <h3 className="text-xs font-medium uppercase tracking-wider text-slate-500">
            {t.prodHeading}
          </h3>
          <p>{t.prodIntro}</p>
          <ul className="list-inside list-disc space-y-1 pl-1">
            <li>{t.prodBulletScrape}</li>
            <li>{t.prodBulletQueue}</li>
            <li>{t.prodBulletMatch}</li>
            <li>{t.prodBulletSheets}</li>
          </ul>
        </section>
      </div>
    </dialog>
  );
}
