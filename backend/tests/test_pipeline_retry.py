"""Tests for pipeline retry errors and worker retry/DLQ settings."""

from app.core.status import JobStatus
from app.services.production.errors import (
    MatchingPipelineError,
    PipelineRetriableError,
    ScrapePipelineError,
)
from app.workers.settings import MAX_RETRIES, WorkerSettings, retry_delay


def test_scrape_pipeline_error_is_retriable() -> None:
    err = ScrapePipelineError("CAPTCHA detected")
    assert isinstance(err, PipelineRetriableError)
    assert err.error_code == "SCRAPE_BLOCKED"
    assert err.status == JobStatus.SCRAPE_FAILED


def test_matching_pipeline_error_is_retriable() -> None:
    err = MatchingPipelineError("PA-API timeout")
    assert isinstance(err, PipelineRetriableError)
    assert err.error_code == "AI_FAILED"
    assert err.status == JobStatus.AI_FAILED


def test_retry_delay_exponential_backoff() -> None:
    assert retry_delay(1) == 30
    assert retry_delay(2) == 60
    assert retry_delay(3) == 120
    assert retry_delay(10) == 300


def test_worker_settings_configured_for_retry_and_dlq() -> None:
    assert WorkerSettings.max_tries == MAX_RETRIES
    assert WorkerSettings.retry_jobs is PipelineRetriableError
    assert WorkerSettings.on_job_failure is not None
    assert WorkerSettings.retry_delay(1) == 30
