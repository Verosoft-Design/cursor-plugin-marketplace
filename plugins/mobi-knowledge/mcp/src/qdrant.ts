/**
 * Qdrant REST client — self-contained copy of packages/ai QdrantVectorStore,
 * trimmed to the search/scroll operations needed by the MCP server.
 */

export type QdrantConfig = {
  url: string;
  apiKey?: string;
};

export type SearchResult = {
  id: string | number;
  score: number;
  payload: Record<string, unknown>;
};

export type SearchFilter = Record<string, string | number | boolean>;

export class QdrantClient {
  private readonly url: string;
  private readonly headers: Record<string, string>;

  constructor(config: QdrantConfig) {
    this.url = config.url.replace(/\/$/, '');
    this.headers = { 'Content-Type': 'application/json' };
    if (config.apiKey) {
      this.headers['api-key'] = config.apiKey;
    }
  }

  /** Semantic vector search */
  async search(
    collection: string,
    vector: number[],
    options: {
      limit?: number;
      filter?: SearchFilter;
      scoreThreshold?: number;
    } = {}
  ): Promise<SearchResult[]> {
    const { limit = 5, filter = {}, scoreThreshold } = options;

    const body: Record<string, unknown> = {
      vector,
      limit,
      with_payload: true,
    };

    const must = Object.entries(filter).map(([key, value]) => ({
      key,
      match: { value },
    }));
    if (must.length > 0) {
      body.filter = { must };
    }

    if (scoreThreshold !== undefined) {
      body.score_threshold = scoreThreshold;
    }

    const data = await this.request(
      'POST',
      `/collections/${collection}/points/search`,
      body
    );

    return (data.result as Record<string, unknown>[]).map((r) => ({
      id: r.id as string,
      score: r.score as number,
      payload: r.payload as Record<string, unknown>,
    }));
  }

  /** List collections available in this Qdrant instance */
  async listCollections(): Promise<string[]> {
    const data = await this.request('GET', '/collections');
    const result = data.result as { collections: { name: string }[] };
    return result.collections.map((c) => c.name);
  }

  /** Get basic info about a collection */
  async collectionInfo(collection: string): Promise<Record<string, unknown>> {
    const data = await this.request('GET', `/collections/${collection}`);
    return data.result as Record<string, unknown>;
  }

  private async request(
    method: string,
    path: string,
    body?: unknown
  ): Promise<Record<string, unknown>> {
    const response = await fetch(`${this.url}${path}`, {
      method,
      headers: this.headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Qdrant ${method} ${path} → ${response.status}: ${text}`);
    }

    const text = await response.text();
    return text ? (JSON.parse(text) as Record<string, unknown>) : {};
  }
}
