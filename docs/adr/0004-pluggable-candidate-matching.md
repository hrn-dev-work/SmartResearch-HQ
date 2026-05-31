# ADR 0004: Pluggable candidate matching

- **Status**: Accepted
- **Date**: 2026-05-31

## Context

Gemini and other LLM quotas are unreliable for production matching volume. Amazon PA-API title search is the default path but must remain swappable.

## Decision

`MATCHING_PROVIDER=amazon_search|none|gemini` with a fixed candidate schema (`asin`, `url`, `title`, `confidence`). When provider is `none`, operators enter ASIN manually.

## Consequences

- `AI_INFERENCE` state means matching in progress, not Gemini-only (legacy name).
- Matching failures map to `AI_FAILED` with retry/DLQ per architecture.

See [design.md §11 D5](../design.md) and [architecture.md §4.2](../architecture.md).
