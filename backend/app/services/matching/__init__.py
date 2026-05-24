from app.services.matching.factory import get_candidate_matcher
from app.services.matching.protocol import CandidateMatcher
from app.services.matching.types import AmazonCandidateMatch

__all__ = ["AmazonCandidateMatch", "CandidateMatcher", "get_candidate_matcher"]
