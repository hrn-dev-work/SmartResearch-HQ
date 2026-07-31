"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";

import { Header } from "@/components/Header";
import { useLocale } from "@/components/LocaleProvider";
import { createResearch } from "@/lib/api";
import {
  bodyCopyClass,
  btnPrimaryClass,
  fieldInputClass,
  pageXClass,
} from "@/lib/ui-classes";

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
        <section className="border-l-2 border-ink pl-4 sm:pl-5">
          <h1 className="text-2xl font-semibold tracking-tight text-ink sm:text-3xl">
            {t.title}
          </h1>
          <p className={`mt-3 ${bodyCopyClass}`}>{t.description}</p>
        </section>

        <section className="mt-10 border-t border-rule pt-10">
          <form onSubmit={handleSubmit} className="space-y-8">
            <div className="space-y-2">
              <label
                htmlFor="shop-url"
                className="block text-sm font-medium text-ink"
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
                  className="text-sm font-medium text-ink"
                >
                  {t.displayNameLabel}
                </label>
                <span className="shrink-0 whitespace-nowrap text-sm text-ink-muted">
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
                className="border-l-2 border-red-700 pl-3 text-sm text-red-700"
                role="alert"
              >
                {error}
              </p>
            )}

            <button type="submit" disabled={loading} className={btnPrimaryClass}>
              {loading ? t.submitting : t.submit}
            </button>
          </form>
        </section>

        <aside className="mt-14 grid gap-8 border-t border-rule pt-10 sm:grid-cols-3 sm:gap-10">
          <Metric
            label={t.metricManual}
            line={`${t.metricManualValue} ${t.metricManualUnit}`}
          />
          <Metric
            label={t.metricTool}
            line={`${t.metricToolValue} ${t.metricToolUnit}`}
            emphasized
          />
          <Metric
            label={t.metricMode}
            line={`${t.metricModeValue} ${t.metricModeUnit}`}
          />
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
    <div className={emphasized ? "text-accent" : "text-ink-muted"}>
      <p className="text-sm text-ink-muted">{label}</p>
      <p
        className={`mt-1.5 text-lg font-semibold tracking-tight tabular-nums sm:text-xl ${
          emphasized ? "text-accent" : "text-ink"
        }`}
      >
        {line}
      </p>
    </div>
  );
}
