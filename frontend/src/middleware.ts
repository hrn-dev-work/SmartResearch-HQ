import type { NextRequest } from "next/server";
import { NextResponse } from "next/server";

import {
  LOCALE_COOKIE,
  LOCALE_COOKIE_MAX_AGE,
  geoToLocale,
  isLocale,
} from "@/lib/locale";

export function middleware(request: NextRequest) {
  const response = NextResponse.next();
  const existing = request.cookies.get(LOCALE_COOKIE)?.value;

  if (isLocale(existing)) {
    return response;
  }

  const country =
    request.headers.get("x-vercel-ip-country") ??
    request.headers.get("cf-ipcountry") ??
    "";
  let locale = geoToLocale(country);
  if (!country) {
    const accept = request.headers.get("accept-language") ?? "";
    if (accept.toLowerCase().includes("ja")) {
      locale = "ja";
    }
  }

  response.cookies.set(LOCALE_COOKIE, locale, {
    path: "/",
    maxAge: LOCALE_COOKIE_MAX_AGE,
    sameSite: "lax",
  });

  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|.*\\..*).*)"],
};
