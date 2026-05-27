#!/usr/bin/env node
/**
 * @mobi/mobi-knowledge MCP server
 *
 * Exposes semantic search over the Verosoft/Mobi knowledge base via Gemini embeddings.
 *
 * Transport is auto-detected:
 *   PORT env set  → Streamable HTTP  (for Linear cloud agents & remote deployments)
 *   PORT not set  → stdio            (for local Cursor desktop)
 *
 * Required env vars:
 *   QDRANT_URL        e.g. https://qdrant.veliox.ai
 *   QDRANT_API_KEY    Qdrant API key
 *   GEMINI_API_KEY    Google AI / Gemini API key
 *
 * Optional:
 *   QDRANT_READ_URL   Override URL for reads (defaults to QDRANT_URL)
 *   PORT              HTTP port — enables HTTP transport when set
 */

import {
  createServer,
  type IncomingMessage,
  type ServerResponse,
} from 'node:http';
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

import { embedText } from './embed.js';
import { QdrantClient } from './qdrant.js';

// ─── Config ──────────────────────────────────────────────────────────────────

const QDRANT_URL = process.env.QDRANT_READ_URL ?? process.env.QDRANT_URL ?? '';
const QDRANT_API_KEY = process.env.QDRANT_API_KEY ?? '';
const GEMINI_API_KEY = process.env.GEMINI_API_KEY ?? '';
const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : undefined;

if (!QDRANT_URL) throw new Error('Missing env: QDRANT_URL or QDRANT_READ_URL');
if (!GEMINI_API_KEY) throw new Error('Missing env: GEMINI_API_KEY');

const qdrant = new QdrantClient({ url: QDRANT_URL, apiKey: QDRANT_API_KEY });

// ─── Collections ─────────────────────────────────────────────────────────────

const COLLECTIONS = [
  'knowledge_base',
  'business_answers',
  'connector_actions',
  'connector_knowledge',
  'connector_specs',
  'user_memories',
  'tool_memories',
  'agent_memories',
  'daily_notes',
  'document_chunks',
  'search_analytics',
  'marketplace_connectors',
] as const;

type Collection = (typeof COLLECTIONS)[number];

// ─── Server factory ───────────────────────────────────────────────────────────

function createMcpServer(): Server {
  const server = new Server(
    { name: 'qdrant-knowledge', version: '1.0.0' },
    { capabilities: { tools: {} } },
  );

  // ── Tool list ───────────────────────────────────────────────────────────────

  server.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: [
      {
        name: 'search_knowledge',
        description:
          'Semantic search over the main knowledge_base collection. ' +
          'Returns the most relevant document chunks for a given query. ' +
          'Use this to answer questions about products, processes, documentation, or any stored knowledge.',
        inputSchema: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'Natural language search query',
            },
            limit: {
              type: 'number',
              description: 'Max results (default 5, max 20)',
            },
            tenant_id: {
              type: 'string',
              description: 'Filter to a specific tenant',
            },
            category: {
              type: 'string',
              description: 'Filter by document category',
            },
            layer: { type: 'string', description: 'Filter by knowledge layer' },
            score_threshold: {
              type: 'number',
              description: 'Min similarity score 0–1 (default 0.3)',
            },
          },
          required: ['query'],
        },
      },
      {
        name: 'search_business_answers',
        description:
          'Semantic search over curated business Q&A pairs. ' +
          'Best for finding pre-written answers to common business questions.',
        inputSchema: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'Natural language question or topic',
            },
            limit: {
              type: 'number',
              description: 'Max results (default 5, max 20)',
            },
            tenant_id: {
              type: 'string',
              description: 'Filter to a specific tenant',
            },
            score_threshold: {
              type: 'number',
              description: 'Min similarity score 0–1 (default 0.3)',
            },
          },
          required: ['query'],
        },
      },
      {
        name: 'search_documents',
        description:
          'Semantic search over user-uploaded document chunks (PDF, Word, Excel, etc.). ' +
          'Use when looking for content from uploaded files.',
        inputSchema: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'Natural language search query',
            },
            limit: {
              type: 'number',
              description: 'Max results (default 5, max 20)',
            },
            tenant_id: {
              type: 'string',
              description: 'Filter to a specific tenant',
            },
            scope: {
              type: 'string',
              description: 'Filter by scope (e.g. "private", "shared")',
            },
            score_threshold: {
              type: 'number',
              description: 'Min similarity score 0–1 (default 0.3)',
            },
          },
          required: ['query'],
        },
      },
      {
        name: 'search_collection',
        description:
          'Low-level semantic search over any named Qdrant collection. ' +
          'Use for connector_actions, connector_knowledge, connector_specs, ' +
          'user_memories, tool_memories, agent_memories, or daily_notes.',
        inputSchema: {
          type: 'object',
          properties: {
            collection: {
              type: 'string',
              enum: COLLECTIONS,
              description: 'Collection to search',
            },
            query: {
              type: 'string',
              description: 'Natural language search query',
            },
            limit: {
              type: 'number',
              description: 'Max results (default 5, max 20)',
            },
            filter: {
              type: 'object',
              description:
                'Key-value payload filter (e.g. { "tenant_id": "abc" })',
              additionalProperties: true,
            },
            score_threshold: {
              type: 'number',
              description: 'Min similarity score 0–1 (default 0.3)',
            },
          },
          required: ['collection', 'query'],
        },
      },
      {
        name: 'list_collections',
        description:
          'List all Qdrant collections available in this knowledge base.',
        inputSchema: { type: 'object', properties: {}, required: [] },
      },
    ],
  }));

  // ── Tool handlers ───────────────────────────────────────────────────────────

  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;
    const a = (args ?? {}) as Record<string, unknown>;

    try {
      switch (name) {
        case 'search_knowledge':
          return formatResults(await semanticSearch('knowledge_base', a));

        case 'search_business_answers':
          return formatResults(await semanticSearch('business_answers', a));

        case 'search_documents':
          return formatResults(await semanticSearch('document_chunks', a));

        case 'search_collection': {
          const collection = a.collection as Collection;
          if (!COLLECTIONS.includes(collection)) {
            return {
              content: [
                {
                  type: 'text' as const,
                  text: `Unknown collection "${collection}". Available: ${COLLECTIONS.join(', ')}`,
                },
              ],
              isError: true,
            };
          }
          return formatResults(await semanticSearch(collection, a));
        }

        case 'list_collections': {
          const collections = await qdrant.listCollections();
          return {
            content: [
              {
                type: 'text' as const,
                text: JSON.stringify({ collections }, null, 2),
              },
            ],
          };
        }

        default:
          return {
            content: [{ type: 'text' as const, text: `Unknown tool: ${name}` }],
            isError: true,
          };
      }
    } catch (err) {
      return {
        content: [
          {
            type: 'text' as const,
            text: `Error: ${err instanceof Error ? err.message : String(err)}`,
          },
        ],
        isError: true,
      };
    }
  });

  return server;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

async function semanticSearch(
  collection: string,
  args: Record<string, unknown>,
) {
  const query = args.query as string;
  const limit = Math.min(Number(args.limit ?? 5), 20);
  const scoreThreshold = (args.score_threshold as number | undefined) ?? 0.3;

  const filter: Record<string, string | number | boolean> = {};
  for (const key of ['tenant_id', 'category', 'layer', 'scope']) {
    if (args[key] !== undefined) filter[key] = args[key] as string;
  }
  if (args.filter && typeof args.filter === 'object') {
    Object.assign(filter, args.filter as Record<string, unknown>);
  }

  const vector = await embedText(query, GEMINI_API_KEY, 'RETRIEVAL_QUERY');
  return qdrant.search(collection, vector, { limit, filter, scoreThreshold });
}

function formatResults(
  results: {
    id: string | number;
    score: number;
    payload: Record<string, unknown>;
  }[],
) {
  if (results.length === 0) {
    return {
      content: [
        {
          type: 'text' as const,
          text: 'No results found above the score threshold.',
        },
      ],
    };
  }
  const formatted = results.map((r, i) => ({
    rank: i + 1,
    id: r.id,
    score: Math.round(r.score * 1000) / 1000,
    ...r.payload,
  }));
  return {
    content: [
      { type: 'text' as const, text: JSON.stringify(formatted, null, 2) },
    ],
  };
}

// ─── Transport ────────────────────────────────────────────────────────────────

async function main() {
  if (PORT !== undefined) {
    // ── HTTP mode (Linear cloud agents / remote deployments) ──────────────────
    log(`Starting in HTTP mode on port ${PORT}`);

    const httpServer = createServer(
      async (req: IncomingMessage, res: ServerResponse) => {
        // Health check
        if (req.method === 'GET' && req.url === '/health') {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ status: 'ok', server: 'qdrant-knowledge' }));
          return;
        }

        // MCP endpoint — stateless: fresh server+transport per request
        if (req.url === '/mcp' || req.url === '/') {
          const server = createMcpServer();
          const transport = new StreamableHTTPServerTransport({
            sessionIdGenerator: undefined,
          });
          await server.connect(transport);
          await transport.handleRequest(req, res);
          return;
        }

        res.writeHead(404);
        res.end('Not found');
      },
    );

    httpServer.listen(PORT, () => {
      log(`Listening on http://0.0.0.0:${PORT}/mcp`);
    });
  } else {
    // ── stdio mode (local Cursor desktop) ─────────────────────────────────────
    log('Starting in stdio mode');
    const server = createMcpServer();
    const transport = new StdioServerTransport();
    await server.connect(transport);
    log('Connected via stdio');
  }
}

function log(msg: string) {
  // Never write to stdout in stdio mode — always use stderr
  process.stderr.write(`[qdrant-mcp] ${msg}\n`);
}

main().catch((err) => {
  process.stderr.write(`[qdrant-mcp] Fatal: ${String(err)}\n`);
  process.exit(1);
});
