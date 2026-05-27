/**
 * Gemini embedding utility
 *
 * Uses gemini-embedding-2-preview with 1536 dimensions — matches the
 * ingestion pipeline in packages/ai so search vectors are compatible.
 */

const EMBEDDING_MODEL = 'gemini-embedding-2-preview';
const EMBEDDING_DIMENSIONS = 1536;
const GEMINI_EMBED_BASE =
  'https://generativelanguage.googleapis.com/v1beta/models';

export type TaskType =
  | 'RETRIEVAL_QUERY'       // use this for search queries (default)
  | 'RETRIEVAL_DOCUMENT'    // use this when indexing documents
  | 'SEMANTIC_SIMILARITY'
  | 'CLASSIFICATION'
  | 'CLUSTERING';

export async function embedText(
  text: string,
  apiKey: string,
  taskType: TaskType = 'RETRIEVAL_QUERY'
): Promise<number[]> {
  const url = `${GEMINI_EMBED_BASE}/${EMBEDDING_MODEL}:embedContent?key=${apiKey}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: `models/${EMBEDDING_MODEL}`,
      content: { parts: [{ text }] },
      taskType,
      outputDimensionality: EMBEDDING_DIMENSIONS,
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Gemini embed error ${response.status}: ${err}`);
  }

  const data = (await response.json()) as {
    embedding: { values: number[] };
  };

  return data.embedding.values;
}
