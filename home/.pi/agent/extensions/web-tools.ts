/**
 * web-tools.ts — Pi extension for web search and webpage fetching
 *
 * Provides two tools:
 *   web_search  — Search the web via DuckDuckGo HTML (no API key required)
 *   web_fetch   — Fetch a URL and extract readable text content
 *
 * Usage:
 *   pi -e ~/.pi/agent/extensions/web-tools.ts
 *   Or place in ~/.pi/agent/extensions/ for auto-discovery.
 *
 * Optional: set SERPAPI_KEY env var to use SerpAPI (Google results) instead of
 * DuckDuckGo for web_search. Get a key at https://serpapi.com/
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function decodeHTMLEntities(text: string): string {
  return text
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#x27;/g, "'")
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, " ")
    .replace(/&#(\d+);/g, (_, d) => String.fromCharCode(Number(d)))
    .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCharCode(parseInt(h, 16)));
}

function stripTags(html: string): string {
  return decodeHTMLEntities(html.replace(/<[^>]*>/g, "")).trim();
}

function extractTextFromHTML(html: string): string {
  let text = html
    // Remove non-content blocks
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
    .replace(/<noscript[^>]*>[\s\S]*?<\/noscript>/gi, "")
    .replace(/<head[^>]*>[\s\S]*?<\/head>/gi, "")
    .replace(/<nav[^>]*>[\s\S]*?<\/nav>/gi, "")
    .replace(/<footer[^>]*>[\s\S]*?<\/footer>/gi, "")
    .replace(/<header[^>]*>[\s\S]*?<\/header>/gi, "")
    .replace(/<svg[\s\S]*?<\/svg>/gi, "")
    // Block elements → newline
    .replace(
      /<\/(div|p|h[1-6]|li|tr|article|section|main|aside|blockquote|pre|table|ul|ol|dl|figure|figcaption|details|summary|form|fieldset)>/gi,
      "\n",
    )
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<hr\s*\/?>/gi, "\n---\n");

  // Remove remaining tags
  text = text.replace(/<[^>]*>/g, "");
  text = decodeHTMLEntities(text);

  // Collapse whitespace
  text = text.replace(/[ \t]+\n/g, "\n").replace(/\n{3,}/g, "\n\n").trim();

  return text;
}

interface SearchResult {
  title: string;
  url: string;
  snippet: string;
}

// ---------------------------------------------------------------------------
// DuckDuckGo HTML search (no API key)
// ---------------------------------------------------------------------------

async function searchDuckDuckGo(
  query: string,
  limit: number,
  signal?: AbortSignal,
): Promise<SearchResult[]> {
  const url =
    `https://html.duckduckgo.com/html/?q=${encodeURIComponent(query)}`;
  const resp = await fetch(url, {
    signal,
    headers: {
      "User-Agent":
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
    },
  });

  if (!resp.ok) {
    throw new Error(`DuckDuckGo returned ${resp.status} ${resp.statusText}`);
  }

  const html = await resp.text();
  const results: SearchResult[] = [];

  // Each result block contains a link (.result__a) and a snippet (.result__snippet)
  // Match: <a class="result__a" href="URL">TITLE</a> ... <a class="result__snippet">SNIPPET</a>
  const blockRe =
    /<a[^>]*class="result__a"[^>]*href="([^"]*)"[^>]*>([\s\S]*?)<\/a>[\s\S]*?<a[^>]*class="result__snippet"[^>]*>([\s\S]*?)<\/a>/gi;

  let match: RegExpExecArray | null;
  while ((match = blockRe.exec(html)) !== null && results.length < limit) {
    const rawUrl = match[1]!;
    // DDG wraps URLs in its own redirect; extract the real URL
    const realUrl = decodeURIComponent(
      rawUrl.replace(/^.*uddg=/, "").replace(/&.*$/, ""),
    );
    const title = stripTags(match[2]!);
    const snippet = stripTags(match[3]!);

    if (title && realUrl.startsWith("http")) {
      results.push({ title, url: realUrl, snippet });
    }
  }

  return results;
}

// ---------------------------------------------------------------------------
// SerpAPI search (optional, set SERPAPI_KEY env var)
// ---------------------------------------------------------------------------

async function searchSerpAPI(
  query: string,
  limit: number,
  signal?: AbortSignal,
): Promise<SearchResult[]> {
  const apiKey = process.env.SERPAPI_KEY;
  if (!apiKey) throw new Error("SERPAPI_KEY not set");

  const url =
    `https://serpapi.com/search?` +
    new URLSearchParams({
      q: query,
      api_key: apiKey,
      engine: "google",
      num: String(Math.min(limit, 10)),
    });

  const resp = await fetch(url, { signal });
  if (!resp.ok) {
    throw new Error(`SerpAPI returned ${resp.status} ${resp.statusText}`);
  }

  const data = (await resp.json()) as {
    organic_results?: Array<{
      title: string;
      link: string;
      snippet: string;
    }>;
  };

  return (data.organic_results ?? []).slice(0, limit).map((r) => ({
    title: r.title,
    url: r.link,
    snippet: r.snippet ?? "",
  }));
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
  // -- web_search -----------------------------------------------------------

  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web for current information. Uses DuckDuckGo by default; " +
      "set the SERPAPI_KEY environment variable to use Google via SerpAPI instead.",
    promptSnippet:
      "Search the web and return titles, URLs, and snippets. Use web_fetch afterwards to get full page content.",
    parameters: Type.Object({
      query: Type.String({ description: "Search query" }),
      limit: Type.Optional(
        Type.Integer({
          minimum: 1,
          maximum: 10,
          default: 5,
          description: "Maximum number of results (1-10, default 5)",
        }),
      ),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, _ctx) {
      const query = params.query;
      const limit = params.limit ?? 5;

      let results: SearchResult[];

      if (process.env.SERPAPI_KEY) {
        results = await searchSerpAPI(query, limit, signal);
      } else {
        results = await searchDuckDuckGo(query, limit, signal);
      }

      if (results.length === 0) {
        return {
          content: [{ type: "text", text: `No results found for: ${query}` }],
          details: { query, results: [] },
        };
      }

      const text = results
        .map(
          (r, i) =>
            `${i + 1}. **${r.title}**\n   URL: ${r.url}\n   ${r.snippet}`,
        )
        .join("\n\n");

      return {
        content: [
          {
            type: "text",
            text: `Search results for "${query}":\n\n${text}`,
          },
        ],
        details: { query, results },
      };
    },
  });

  // -- web_fetch ------------------------------------------------------------

  pi.registerTool({
    name: "web_fetch",
    label: "Web Fetch",
    description:
      "Fetch a webpage URL and return its text content. Strips HTML tags, " +
      "scripts, and styles to return readable text. Use after web_search to " +
      "read full article content.",
    promptSnippet:
      "Fetch a URL and return extracted text. Use after web_search to read pages.",
    parameters: Type.Object({
      url: Type.String({ description: "Full URL to fetch (https://...)" }),
      raw: Type.Optional(
        Type.Boolean({
          default: false,
          description:
            "If true, return raw HTML instead of extracted text",
        }),
      ),
    }),
    async execute(_toolCallId, params, signal, _onUpdate, _ctx) {
      const url = params.url;
      const raw = params.raw ?? false;

      const resp = await fetch(url, {
        signal,
        headers: {
          "User-Agent":
            "Mozilla/5.0 (compatible; PiAgent/1.0; +https://pi.dev)",
          Accept:
            "text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.8",
          "Accept-Language": "en-US,en;q=0.5",
        },
        redirect: "follow",
      });

      if (!resp.ok) {
        throw new Error(
          `Failed to fetch ${url}: ${resp.status} ${resp.statusText}`,
        );
      }

      const contentType = resp.headers.get("content-type") ?? "";
      const body = await resp.text();

      let output: string;

      if (raw) {
        output = body;
      } else if (contentType.includes("text/html")) {
        output = extractTextFromHTML(body);
      } else {
        output = body;
      }

      // Truncate to ~10K tokens (≈50KB) to avoid overwhelming the LLM
      const MAX_BYTES = 50_000;
      let truncated = false;
      if (output.length > MAX_BYTES) {
        output = output.slice(0, MAX_BYTES);
        truncated = true;
      }

      const header =
        `Content from ${url}\n` +
        `Content-Type: ${contentType}\n` +
        `Length: ${output.length} chars` +
        (truncated ? ` (truncated from ${body.length})` : "") +
        `\n\n`;

      return {
        content: [{ type: "text", text: header + output }],
        details: {
          url,
          contentType,
          length: output.length,
          truncated,
        },
      };
    },
  });

  // Log on startup
  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode === "tui") {
      const backend = process.env.SERPAPI_KEY ? "SerpAPI (Google)" : "DuckDuckGo";
      ctx.ui.notify(`Web tools loaded (search: ${backend})`, "info");
    }
  });
}
