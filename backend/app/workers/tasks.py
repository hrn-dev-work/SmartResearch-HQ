"""
Background job pipeline (Phase 2):
  scrape → persist items → candidate matching → AWAITING_REVIEW

Matching provider (MATCHING_PROVIDER):
  amazon_search (default) | none | gemini (optional)
On failure: retry with backoff or dead-letter queue.
"""

from app.services.production.pipeline import run_job_pipeline
from app.workers.settings import process_research_job

__all__ = ["process_research_job", "run_job_pipeline"]
