from uuid import uuid4

from app.db.models import ReviewDecision
from app.services.review.decision_marker import decision_marker


def test_decision_marker_candidate() -> None:
    candidate_id = uuid4()
    decision = ReviewDecision(
        job_item_id=uuid4(),
        chosen_candidate_id=candidate_id,
        rejected=False,
    )
    assert decision_marker(decision) == candidate_id


def test_decision_marker_rejected() -> None:
    decision_id = uuid4()
    decision = ReviewDecision(
        id=decision_id,
        job_item_id=uuid4(),
        rejected=True,
    )
    assert decision_marker(decision) == decision_id


def test_decision_marker_manual_asin() -> None:
    decision_id = uuid4()
    decision = ReviewDecision(
        id=decision_id,
        job_item_id=uuid4(),
        manual_asin="B012345678",
        rejected=False,
    )
    assert decision_marker(decision) == decision_id
