from functools import lru_cache

from app.config import MatchingProvider, get_settings
from app.services.matching.amazon_search import AmazonSearchMatcher
from app.services.matching.gemini import GeminiMatcher
from app.services.matching.manual import ManualMatcher
from app.services.matching.protocol import CandidateMatcher


@lru_cache
def get_candidate_matcher() -> CandidateMatcher:
    settings = get_settings()
    match settings.matching_provider:
        case MatchingProvider.AMAZON_SEARCH:
            return AmazonSearchMatcher(settings)
        case MatchingProvider.NONE:
            return ManualMatcher()
        case MatchingProvider.GEMINI:
            return GeminiMatcher(settings)
