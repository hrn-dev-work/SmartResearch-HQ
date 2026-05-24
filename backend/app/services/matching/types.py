from dataclasses import dataclass


@dataclass
class AmazonCandidateMatch:
    asin: str
    amazon_url: str
    title: str
    confidence: float
    reasoning: str | None = None
