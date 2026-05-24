export type JobStatus =
  | "PENDING"
  | "SCRAPING"
  | "SCRAPE_FAILED"
  | "AI_INFERENCE"
  | "AI_FAILED"
  | "AWAITING_REVIEW"
  | "APPROVED"
  | "REJECTED"
  | "EXPORTED";

export interface CreateResearchResponse {
  job_id: string;
  status: JobStatus;
  progress_pct: number;
}

export interface ResearchJob {
  job_id: string;
  status: JobStatus;
  progress_pct: number;
  seller: {
    shopee_shop_url: string;
    display_name: string | null;
  };
  item_count: number;
  error: { code: string; message: string } | null;
  created_at: string;
  updated_at: string;
}

export interface AmazonCandidate {
  candidate_id: string;
  rank: number;
  asin: string;
  amazon_url: string;
  title: string;
  confidence: number;
}

export interface ReviewItem {
  item_id: string;
  title: string;
  image_url: string;
  sold_count: number | null;
  candidates: AmazonCandidate[];
  decision: string | null;
}

export interface ReviewItemsPage {
  items: ReviewItem[];
  page: number;
  page_size: number;
  total: number;
}
