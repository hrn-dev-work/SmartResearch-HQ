import { ja } from "@/lib/messages/ja";

/** Widen `as const` string literals so ja/en catalogs share one type. */
type DeepString<T> = T extends string
  ? string
  : T extends object
    ? { [K in keyof T]: DeepString<T[K]> }
    : T;

export type Messages = DeepString<typeof ja>;
