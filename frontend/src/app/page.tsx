"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

import { Header } from "@/components/Header";
import { useLocale } from "@/components/LocaleProvider";
import { createResearch } from "@/lib/api";
import { bodyCopyClass, fieldInputClass, pageXClass } from "@/lib/ui-classes";

export default function DashboardPage() {
  const router = useRouter();
  const { messages } = useLocale();
  const t = messages.dashboard;

  const [url, setUrl] = useState("https://shopee.sg/demo-shop");
  const [name, setName] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      const res = await createResearch(url, name || undefined);
      router.push(`/review/${res.job_id}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : t.errorStart);
    } finally {
      setLoading(false);
    }
  }

  return (
    <>
      <Header />
      <main
        className={`mx-auto w-full max-w-3xl flex-1 py-10 sm:py-14 ${pageXClass}`}
      >
        <section className="space-y-3">
          <h1 className="text-2xl font-semibold tracking-tight text-slate-900 sm:text-3xl">
            {t.title}
          </h1>
          <p className={bodyCopyClass}>{t.description}</p>
        </section>

        <section className="mt-10 border-t border-slate-200 pt-10">
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-2">
              <label
                htmlFor="shop-url"
                className="block text-sm font-medium text-slate-900"
              >
                {t.shopUrlLabel}
              </label>
              <input
                id="shop-url"
                type="url"
                required
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                className={fieldInputClass}
                placeholder={t.shopUrlPlaceholder}
              />
            </div>

            <div className="space-y-2">
              <div className="flex flex-wrap items-baseline gap-x-2 gap-y-0.5">
                <label
                  htmlFor="shop-name"
                  className="text-sm font-medium text-slate-900"
                >
                  {t.displayNameLabel}
                </label>
                <span className="shrink-0 text-sm text-slate-500">
                  {t.displayNameOptional}
                </span>
              </div>
              <input
                id="shop-name"
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className={fieldInputClass}
                placeholder={t.displayNamePlaceholder}
              />
            </div>

            {error && (
              <p
                className="border-l-2 border-red-500 pl-3 text-sm text-red-600"
                role="alert"
              >
                {error}
              </p>
            )}

            <button
              type="submit"
              disabled={loading}
              className="inline-flex w-full items-center justify-center rounded-md bg-slate-900 px-6 py-2.5 text-sm font-medium text-white transition-colors duration-200 hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2 active:scale-[0.98] disabled:pointer-events-none disabled:opacity-50 sm:w-auto"
            >
              {loading ? t.submitting : t.submit}
            </button>
          </form>
        </section>

        <aside className="mt-14 grid gap-6 border-t border-slate-200 pt-10 sm:grid-cols-3 sm:gap-8">
          <Metric label={t.metricManualLabel} line={t.metricManualLine} />
          <Metric label={t.metricToolLabel} line={t.metricToolLine} emphasized />
          <Metric label={t.metricModeLabel} line={t.metricModeLine} />
        </aside>
      </main>
    </>
  );
}

function Metric({
  label,
  line,
  emphasized,
}: {
  label: string;
  line: string;
  emphasized?: boolean;
}) {
  return (
    <div className={emphasized ? "text-slate-900" : "text-slate-600"}>
      <p className="text-sm text-slate-500">{label}</p>
      <p className="mt-1.5 text-lg font-semibold tracking-tight text-slate-900 sm:text-xl">
        {line}
      </p>
    </div>
  );
}
