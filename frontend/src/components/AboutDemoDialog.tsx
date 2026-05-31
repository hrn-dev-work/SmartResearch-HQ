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
<<<<<<< HEAD
      className="fixed inset-0 z-50 m-auto flex w-[min(100%,32rem)] max-h-[min(90vh,36rem)] flex-col overflow-y-auto rounded-md border border-slate-200 bg-white p-0 text-slate-900 backdrop:bg-slate-900/20 open:flex"
=======
      className="fixed inset-0 z-50 m-auto flex w-[min(100%,32rem)] max-h-[min(90vh,36rem)] flex-col overflow-y-auto rounded-md border border-slate-200 bg-white p-0 text-slate-900 backdrop:bg-slate-900/20"
>>>>>>> origin/main
    >
      <div className="border-b border-slate-200 px-5 py-4 sm:px-6 sm:py-5">
        <div className="flex items-start justify-between gap-4">
          <div className="min-w-0">
            <h2 className="text-lg font-semibold tracking-tight text-slate-900">
              {a.title}
            </h2>
            <p className="mt-1 text-pretty text-sm text-slate-500">
              {a.subtitle}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="shrink-0 rounded-md px-2 py-1 text-sm text-slate-500 transition-colors duration-200 hover:bg-slate-100 hover:text-slate-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2"
            aria-label={a.close}
          >
            {a.close}
          </button>
        </div>
      </div>

      <div className="space-y-8 px-5 py-6 text-pretty text-sm leading-relaxed text-slate-600 sm:px-6">
        <section className="space-y-2">
          <h3 className="text-sm font-medium text-slate-900">
            {a.purposeHeading}
          </h3>
          <p>{a.purposeBody}</p>
        </section>

        <section className="space-y-2">
          <h3 className="text-sm font-medium text-slate-900">{a.archHeading}</h3>
          <p>{a.archIntro}</p>
          <ul className="list-disc space-y-1.5 pl-5">
            <li>{a.archBulletMock}</li>
            <li>{a.archBulletFixture}</li>
          </ul>
        </section>

        <section className="space-y-2">
          <h3 className="text-sm font-medium text-slate-900">{a.prodHeading}</h3>
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
