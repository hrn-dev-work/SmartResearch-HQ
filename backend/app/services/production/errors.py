"""Pipeline errors for worker retry / DLQ handling."""

from app.core.status import JobStatus


class PipelineError(Exception):
    def __init__(
        self,
        message: str,
        *,
        error_code: str,
        status: JobStatus,
    ) -> None:
        self.error_code = error_code
        self.status = status
        super().__init__(message)


class PipelineRetriableError(PipelineError):
    """Scrape/matching failure that ARQ should retry with backoff."""


class ScrapePipelineError(PipelineRetriableError):
    def __init__(self, message: str, *, error_code: str = "SCRAPE_BLOCKED") -> None:
        super().__init__(
            message,
            error_code=error_code,
            status=JobStatus.SCRAPE_FAILED,
        )


class MatchingPipelineError(PipelineRetriableError):
    def __init__(self, message: str, *, error_code: str = "AI_FAILED") -> None:
        super().__init__(
            message,
            error_code=error_code,
            status=JobStatus.AI_FAILED,
        )
