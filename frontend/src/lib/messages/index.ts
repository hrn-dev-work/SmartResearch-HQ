import type { Locale } from "@/lib/locale";
import { en } from "@/lib/messages/en";
import { ja, type Messages } from "@/lib/messages/ja";

export type { Messages } from "@/lib/messages/ja";
export { interpolate } from "@/lib/messages/interpolate";

const CATALOG: Record<Locale, Messages> = { ja, en };

export function getMessages(locale: Locale): Messages {
  return CATALOG[locale];
}
