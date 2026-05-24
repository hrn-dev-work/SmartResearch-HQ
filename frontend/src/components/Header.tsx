import Link from "next/link";

export function Header() {
  return (
    <header className="border-b border-slate-200/80 bg-white/80 backdrop-blur-sm">
      <div className="mx-auto flex max-w-3xl items-center justify-between px-6 py-4">
        <Link
          href="/"
          className="group flex items-center gap-3 transition-opacity duration-200 hover:opacity-80"
        >
          <span className="flex h-8 w-8 items-center justify-center rounded-md bg-slate-900 text-xs font-semibold tracking-tight text-white transition-transform duration-200 group-hover:scale-[1.02]">
            SR
          </span>
          <span className="text-base font-semibold tracking-tight text-slate-900">
            SmartResearch
          </span>
        </Link>
        <span className="text-xs font-medium text-slate-500">Demo</span>
      </div>
    </header>
  );
}
