"use client";

import { useEffect, useRef } from "react";

import { useLocale } from "@/components/LocaleProvider";

type AboutDemoDialogProps = {
  open: boolean;
  onClose: () => void;
};

export function AboutDemoDialog({ open, onClose }: AboutDemoDialogProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const { messages } = useLocale();
  const a = messages.about;

  useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (open) {
      if (!dialog.open) dialog.showModal();
    } else if (dialog.open) {
      dialog.close();
    }
  }, [open]);

  if (!open) {
    return null;
  }

  return (
    <dialog
      ref={dialogRef}
      onClose={onClose}
      className="fixed inset-0 z-50 m-auto flex w-[min(100%,32rem)] max-h-[min(90vh,36rem)] flex-col overflow-y-auto rounded-sm border border-rule bg-surface p-0 text-ink backdrop:bg-ink/25"
    >
      <div className="border-b border-rule px-5 py-4 sm:px-6 sm:py-5">
        <div className="flex items-start justify-between gap-4">
          <div className="min-w-0">
            <h2 className="text-lg font-semibold tracking-tight text-ink">
              {a.title}
            </h2>
            <p className="mt-1 text-pretty text-sm text-ink-muted">{a.subtitle}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="shrink-0 rounded-sm px-2 py-1 text-sm text-ink-muted transition-colors duration-200 hover:bg-paper hover:text-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ink/25 focus-visible:ring-offset-2 focus-visible:ring-offset-surface"
            aria-label={a.close}
          >
            {a.close}
          </button>
        </div>
      </div>

      <div className="space-y-8 px-5 py-6 text-pretty text-sm leading-relaxed text-ink-muted sm:px-6">
        <section className="space-y-2">
          <h3 className="text-sm font-medium text-ink">{a.purposeHeading}</h3>
          <p>
            {a.purposeBodyBefore}
            <strong className="font-medium text-ink">{a.purposeEmphasis}</strong>
            {a.purposeBodyAfter}
          </p>
        </section>

        <section className="space-y-2">
          <h3 className="text-sm font-medium text-ink">{a.archHeading}</h3>
          <p>
            {a.archIntroBefore}
            <strong className="font-medium text-ink">{a.archPortfolio}</strong>
            {a.archIntroMid}
            <strong className="font-medium text-ink">{a.archProduction}</strong>
            {a.archIntroAfter}
          </p>
          <ul className="list-disc space-y-1.5 pl-5">
            <li>{a.archBulletMock}</li>
            <li>{a.archBulletFixture}</li>
          </ul>
        </section>

        <section className="space-y-2">
          <h3 className="text-sm font-medium text-ink">{a.prodHeading}</h3>
          <p>{a.prodIntro}</p>
          <ul className="list-disc space-y-1.5 pl-5">
            <li>{a.prodBulletScrape}</li>
            <li>{a.prodBulletQueue}</li>
            <li>{a.prodBulletMatch}</li>
            <li>{a.prodBulletSheets}</li>
          </ul>
        </section>
      </div>
    </dialog>
  );
}
