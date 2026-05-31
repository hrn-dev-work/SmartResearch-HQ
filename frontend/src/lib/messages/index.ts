import type { Locale } from "@/lib/locale";
import { en } from "@/lib/messages/en";
import { ja } from "@/lib/messages/ja";
import type { Messages } from "@/lib/messages/types";

export type { Messages } from "@/lib/messages/types";
export { interpolate } from "@/lib/messages/interpolate";

const CATALOG: Record<Locale, Messages> = { ja, en };

export function getMessages(locale: Locale): Messages {
  return CATALOG[locale];
}
