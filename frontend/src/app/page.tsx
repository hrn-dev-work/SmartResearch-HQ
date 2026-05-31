"use client";

import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";

import { Header } from "@/components/Header";
import { useLocale } from "@/components/LocaleProvider";
import { createResearch } from "@/lib/api";

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
      <main className="mx-auto w-full max-w-3xl flex-1 px-6 py-16">
        <section className="space-y-3">
          <h1 className="text-3xl font-semibold tracking-tight text-slate-900">
            {t.title}
          </h1>
          <p className="max-w-lg text-base leading-relaxed text-slate-500">
            {t.description}
          </p>
        </section>

        <section className="mt-16 space-y-8">
          <form onSubmit={handleSubmit} className="space-y-8">
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
                className="w-full border-b border-slate-200 bg-transparent py-3 text-base text-slate-900 placeholder:text-slate-400 transition-colors duration-200 focus:border-slate-900 focus:outline-none"
                placeholder={t.shopUrlPlaceholder}
              />
            </div>

            <div className="space-y-2">
              <label
                htmlFor="shop-name"
                className="block text-sm font-medium text-slate-900"
              >
                {t.displayNameLabel}
                <span className="ml-1 font-normal text-slate-500">
                  {t.displayNameOptional}
                </span>
              </label>
              <input
                id="shop-name"
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full border-b border-slate-200 bg-transparent py-3 text-base text-slate-900 placeholder:text-slate-400 transition-colors duration-200 focus:border-slate-900 focus:outline-none"
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
              className="inline-flex items-center justify-center rounded-md bg-slate-900 px-6 py-2.5 text-sm font-medium text-white transition-all duration-200 hover:bg-slate-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2 active:scale-[0.98] disabled:pointer-events-none disabled:opacity-50"
            >
              {loading ? t.submitting : t.submit}
            </button>
          </form>
        </section>

        <aside className="mt-24 grid gap-8 border-t border-slate-200 pt-12 sm:grid-cols-3">
          <Metric
            label={t.metricManual}
            value={t.metricManualValue}
            unit={t.metricManualUnit}
          />
          <Metric
            label={t.metricTool}
            value={t.metricToolValue}
            unit={t.metricToolUnit}
            highlight
          />
          <Metric
            label={t.metricMode}
            value={t.metricModeValue}
            unit={t.metricModeUnit}
          />
        </aside>
      </main>
    </>
  );
}

function Metric({
  label,
  value,
  unit,
  highlight,
}: {
  label: string;
  value: string;
  unit: string;
  highlight?: boolean;
}) {
  return (
    <div className={highlight ? "text-slate-900" : "text-slate-500"}>
      <p className="text-xs font-medium uppercase tracking-wider text-slate-500">
        {label}
      </p>
      <p className="mt-2 text-2xl font-semibold tracking-tight text-slate-900">
        {value}
      </p>
      <p className="mt-1 text-sm text-slate-500">{unit}</p>
    </div>
  );
}
