import type {
  CreateResearchResponse,
  ExportJobResponse,
  ResearchJob,
  ReviewItemsPage,
} from "./types";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...init?.headers,
    },
  });
  if (!res.ok) {
    const body = (await res.json().catch(() => ({}))) as {
      error?: { message?: string };
      detail?: { error?: { message?: string } };
    };
    const message =
      body.error?.message ??
      body.detail?.error?.message ??
      res.statusText;
    throw new Error(message);
  }
  return res.json() as Promise<T>;
}

export async function createResearch(
  shopeeShopUrl: string,
  sellerDisplayName?: string,
): Promise<CreateResearchResponse> {
  return request<CreateResearchResponse>("/research", {
    method: "POST",
    body: JSON.stringify({
      shopee_shop_url: shopeeShopUrl,
      seller_display_name: sellerDisplayName || null,
    }),
  });
}

export async function getResearchJob(jobId: string): Promise<ResearchJob> {
  return request<ResearchJob>(`/research/${jobId}`);
}

export async function getReviewItems(
  jobId: string,
  page = 1,
  pageSize = 20,
): Promise<ReviewItemsPage> {
  return request<ReviewItemsPage>(
    `/research/${jobId}/items?page=${page}&page_size=${pageSize}`,
  );
}

export type DecideReviewOptions = {
  candidateId?: string | null;
  manualAsin?: string;
  rejected?: boolean;
};

export async function decideReview(
  itemId: string,
  candidateIdOrOptions: string | null | DecideReviewOptions,
  rejected = false,
): Promise<void> {
  const options: DecideReviewOptions =
    typeof candidateIdOrOptions === "object" && candidateIdOrOptions !== null
      ? candidateIdOrOptions
      : { candidateId: candidateIdOrOptions, rejected };

  await request(`/review/${itemId}/decide`, {
    method: "POST",
    body: JSON.stringify({
      candidate_id: options.candidateId ?? null,
      manual_asin: options.manualAsin ?? null,
      rejected: options.rejected ?? false,
    }),
  });
}

export async function exportJob(jobId: string): Promise<ExportJobResponse> {
  return request<ExportJobResponse>(`/research/${jobId}/export`, { method: "POST" });
}

export async function checkHealth(): Promise<{
  status: string;
  mode: string;
  matching_provider?: string;
}> {
  return request("/health");
}
