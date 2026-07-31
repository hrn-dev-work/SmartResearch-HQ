import type { Metadata } from "next";
import { IBM_Plex_Sans_JP } from "next/font/google";
import { cookies } from "next/headers";

import { LocaleProvider } from "@/components/LocaleProvider";
import { getMessages } from "@/lib/messages";
import { LOCALE_COOKIE, normalizeLocale } from "@/lib/locale";

import "./globals.css";

const ibmPlexSansJp = IBM_Plex_Sans_JP({
  variable: "--font-ibm-plex-sans-jp",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

export async function generateMetadata(): Promise<Metadata> {
  const cookieStore = await cookies();
  const locale = normalizeLocale(cookieStore.get(LOCALE_COOKIE)?.value);
  const m = getMessages(locale);
  return {
    title: m.meta.title,
    description: m.meta.description,
  };
}

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const cookieStore = await cookies();
  const locale = normalizeLocale(cookieStore.get(LOCALE_COOKIE)?.value);
  const messages = getMessages(locale);

  return (
    <html
      lang={locale}
      className={`${ibmPlexSansJp.variable} h-full antialiased`}
    >
      <body className="flex min-h-full flex-col bg-paper font-sans text-ink">
        <LocaleProvider locale={locale} messages={messages}>
          {children}
        </LocaleProvider>
      </body>
    </html>
  );
}
