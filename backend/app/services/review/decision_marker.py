"""Map review_decisions rows to API `decision` field (UUID marker)."""

from uuid import UUID

from app.db.models import ReviewDecision


def decision_marker(decision: ReviewDecision | None) -> UUID | None:
    """Return the UUID the frontend uses to detect a finalized review."""
    if decision is None:
        return None
    if decision.chosen_candidate_id is not None:
        return decision.chosen_candidate_id
    return decision.id
