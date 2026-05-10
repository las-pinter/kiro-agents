---
name: source-selection
description: >-
  Decision rules for choosing between Context7, DeepWiki, and Exa based on query
  type. Use BEFORE every research action to select the appropriate source — do
  NOT skip this skill and guess which source to use. This skill provides a
  systematic query classification system, multi-source orchestration patterns,
  source quality heuristics, and fallback chains. Consult it whenever you need
  to research any topic: library APIs, repository internals, web searches,
  comparisons, current information, or debugging. If you're about to open a
  browser or search tool without consulting this skill first, STOP and read it.
---

# Source Selection — Systematic Source Intelligence

A researcher is only as good as their sources. Using the wrong source wastes
queries, returns stale results, or misses critical context. This skill gives
you a repeatable methodology to match every query to its optimal source.

---

## Methodology Overview

```
1. CLASSIFY   → What type of query is this? (API? Architecture? Current info?)
2. MATCH      → Pick the primary source from the decision tree
3. EXECUTE    → Query the source with optimal parameters
4. EVALUATE   → Did the source return useful results? Use quality heuristics.
5. CHAIN      → If results are insufficient, follow the orchestration pattern
6. VERIFY     → Cross-reference critical findings across 2+ sources
```

---

## Step 1: Query Classification

Not all queries are the same. Classify your query FIRST, then pick the source.

### Query Type Taxonomy

| Type | Description | Examples | Optimal Source |
|------|-------------|----------|----------------|
| **API Reference** | Exact API usage, parameters, return types, configuration | "How to use `useEffect` in React 18" | **Context7** (version-pinned) |
| **Repo Architecture** | How a project is structured, its internals, design decisions | "How does Next.js handle route groups internally?" | **DeepWiki** |
| **Current Information** | News, recent releases, trends, live data | "What's new in Next.js 16?" | **Exa** (with date filter) |
| **Best Practices** | Community conventions, tutorials, patterns | "Best practices for error handling in Go" | **Exa** |
| **Comparison** | Side-by-side evaluation of options | "Redis vs Memcached for caching" | **Exa** (then verify with Context7) |
| **Debugging** | Troubleshooting specific errors or behaviors | "NextAuth getServerSession returning null" | **Exa** (issue threads, then DeepWiki for source) |
| **Concept Explanation** | Understanding a high-level concept or theory | "What is the actor model?" | **Exa** (articles, then Context7 for language-specific impl) |
| **Verification** | Confirming a fact or approach is correct | "Is `Math.random()` cryptographically secure?" | **Cross-reference: Context7 (docs) + Exa (discussions)** |
| **Unknown Territory** | No clear idea where to start | "How do I add authentication to my app?" | **Exa first** (overviews), **then** Context7 (specific lib docs) |

### Classification Quick-Check

If you're unsure which type, ask:
- Am I looking for **how to use** something? → API Reference
- Am I looking for **how it works** internally? → Repo Architecture
- Am I looking for **what people say** about it? → Best Practices / Current Info
- Am I looking for **why something broke**? → Debugging
- Am I looking for **what's best**? → Comparison
- Am I looking for **what this thing even is**? → Concept Explanation / Unknown Territory

---

## Step 2: Source Decision Tree

```
Q1: Is this about a SPECIFIC library/framework's API, config, or usage?
  → YES: Does Context7 have a library ID for it?
      → YES → Use Context7 (resolve ID first, then query)
      → NO  → Is it on GitHub with docs?
          → YES → Try DeepWiki (repo structure + docs)
          → NO  → Use Exa
  → NO:  Proceed to Q2.

Q2: Is this about a SPECIFIC GitHub repository's architecture or internals?
  → YES: Use DeepWiki
  → NO:  Proceed to Q3.

Q3: Does this require CURRENT information (news, releases, trends)?
  → YES: Use Exa with date filters
  → NO:  Proceed to Q4.

Q4: Does this need community knowledge (best practices, tutorials, comparisons)?
  → YES: Use Exa
  → NO:  Proceed to Q5.

Q5: Is this a concept explanation or unknown territory?
  → YES: Start with Exa for overview, then drill into specific tools via Context7
  → NO:  Proceed to Q6.

Q6: Is this verification (confirming something is correct)?
  → YES: Cross-reference 2+ sources (Context7 + Exa, or DeepWiki + Exa)
  → NO:  Proceed to default.

DEFAULT: Start with Exa (broadest coverage), then narrow with
         Context7 or DeepWiki if more specific sources needed.
```

---

## Step 3: Source-Specific Execution

### Context7 — Best For: API Reference, Version-Specific Docs, Code Examples

**Always resolve a library ID first:**
```
context7_resolve(libraryName="Next.js", query="...")
→ Use the resolved /org/project ID for the actual query
→ Pin to a version if the user specifies one: /vercel/next.js/v14.3.0
```

**Optimal queries:**
- Be SPECIFIC: "How to set up middleware with matcher config in Next.js 14"
- Include context: "Usage with TypeScript and App Router"
- Don't ask for overviews you could get from a README

**Quality heuristics:**
| Signal | Good Result | Weak Result |
|--------|------------|-------------|
| Code snippets | ✅ 3+ relevant snippets with context | ❌ No code, or code from 3 versions ago |
| Version match | ✅ Exactly the version asked about | ❌ Wrong version or no version specified |
| Coverage | ✅ Multiple relevant results | ❌ Only 1-2 tangentially related results |

**When Context7 results are weak:** Try DeepWiki (repo docs may have more).

### DeepWiki — Best For: Repo Architecture, Internal Design, Source Structure

**Pick the right repo:**
- Use the exact owner/repo format: `vercel/next.js`, `facebook/react`
- For monorepos, specify the relevant package if DeepWiki supports it

**Optimal queries:**
- Structural: "How does the routing system work?"
- Relationship: "How do pages and layouts relate to each other?"
- Internals: "How is the bundling pipeline structured?"

**Quality heuristics:**
| Signal | Good Result | Weak Result |
|--------|------------|-------------|
| Architecture detail | ✅ Clear component relationships | ❌ Vague "see the code" responses |
| File references | ✅ Points to specific files/directories | ❌ No concrete references |
| Readability | ✅ Well-organized explanation | ❌ Wall of text, no structure |

**When DeepWiki results are weak:** Try Exa for blog posts or tutorials about the repo.

### Exa — Best For: Current Info, Best Practices, Tutorials, Comparisons

**Always use natural language queries:**
- Describe the ideal page, not keywords
  ✅ "blog post comparing React Server Components vs Client Components performance 2025"
  ❌ "React Server Components vs Client Components"

**Date filtering for current info:**
- The current year is 2026. Use `after:2025` or `after:2026` for recent content.
- For evergreen topics (concepts, fundamentals), date filtering is less critical.

**Quality heuristics:**
| Signal | Good Result | Weak Result |
|--------|------------|-------------|
| Recency | ✅ Published within last 12 months | ❌ Published 3+ years ago for a fast-moving topic |
| Authority | ✅ Official docs, well-known blogs, high-quality tutorials | ❌ Random forum post with no citations |
| Depth | ✅ Covers the topic thoroughly | ❌ Clickbait headline, shallow content |

**When Exa results are weak:** Try fetching the full page content with `web_fetch_exa`
for a result that looked promising in highlights.

---

## Step 4: Multi-Source Orchestration Patterns

Some queries need MULTIPLE sources. Here are the proven patterns:

### Pattern 1: API + Practice (most common)
```
Context7 → Exa
```
Get the official API from Context7, then find real-world usage on Exa.

*Example: "How do I use React Query's useMutation?"*
1. Context7: Get the API signature and options
2. Exa: Find blog posts showing real implementations

### Pattern 2: Architecture + API
```
DeepWiki → Context7
```
Understand the system architecture first, then drill into specific APIs.

*Example: "How does Next.js middleware work with the edge runtime?"*
1. DeepWiki: Understand the middleware pipeline architecture
2. Context7: Get the exact API for middleware configuration

### Pattern 3: Overview → Deep Dive
```
Exa → Context7 (or DeepWiki)
```
Get a lay of the land, then go deep.

*Example: "I need to add real-time features to my app"*
1. Exa: Find overviews of WebSocket vs SSE vs WebRTC approaches
2. Context7: Get API details for the chosen library (e.g., Socket.IO)

### Pattern 4: Debugging
```
Exa → DeepWiki → Context7
```
Find the error first, then trace the source, then verify the fix.

*Example: "Getting 'Module not found' error with Next.js dynamic imports"*
1. Exa: Search for the error message, find GitHub issues and solutions
2. DeepWiki: Understand how Next.js resolves dynamic imports internally
3. Context7: Verify the correct dynamic import API

### Pattern 5: Critical Verification
```
Context7 + Exa (in parallel)
```
Cross-reference a critical claim from two independent sources.

*Example: "Is this deprecation warning real or a false positive?"*
1. Context7: Check the official changelog or deprecation notice
2. Exa: Find community discussions confirming the deprecation

### Pattern 6: Unknown Territory
```
Exa → [Context7 or DeepWiki] → Exa
```
Start broad, go deep, then validate.

*Example: "I need to build a CLI tool in Rust"*
1. Exa: Find "best CLI frameworks in Rust" articles
2. Context7: Get API docs for the chosen framework (e.g., clap)
3. Exa: Find tutorials and real-world examples

---

## Step 5: Fallback Chain

When your primary source fails, follow this chain:

```
1st choice:  Optimal source (from decision tree)
  ↓ (if results are poor)
2nd choice:  Next best source (from orchestration patterns)
  ↓ (if still poor)
3rd choice:  Broadest source (Exa by default)
  ↓ (if still poor)
4th choice:  Web fetch (web_fetch_exa) on specific promising URLs
  ↓ (if still poor)
Report back: "Unable to find satisfactory results for this query"
```

---

## Examples

### Good Example

**Query:** "What's the proper way to use Next.js 14 Server Actions with form validation?"

**Classification:** API Reference + Best Practices (mixed)

**Source selection:**

1. **Context7** → Resolve `/vercel/next.js` → Query for "Server Actions with form validation"
   - Result: API reference for `useActionState`, `"use server"` directive, form handling
   - Quality: Good — version-pinned, includes code snippets

2. **Exa** (chained) → Search "Next.js Server Actions form validation best practices 2025"
   - Result: Blog posts with real patterns, error handling approaches, loading states
   - Quality: Good — recent, from authoritative dev blogs

**Result:** Complete picture — official API + real-world practice.

### Bad Example — What NOT to Do

**Query:** "How does Prisma connection pooling work?"

**Wrong approach:**
```
❌ Exa search: "Prisma connection pooling"
   - Gets blog posts, maybe outdated, no official API reference
```

**Correct approach:**
```
✅ Context7: Resolve /prisma/prisma → Query "connection pooling configuration"
   - Gets official docs, API signatures, version-specific behavior
✅ Then Exa: "Prisma connection pooling best practices production 2025"
   - Gets real-world deployment patterns
```

**Why the wrong approach fails:** Exa for API reference misses version-specific
behavior, may return outdated patterns, and doesn't have the authoritative
source. Context7 should always be first for library-specific questions.

---

## Anti-Patterns

| ❌ Don't | ✅ Do Instead | Why |
|----------|--------------|-----|
| Use Exa for API reference when Context7 has it | Use Context7 first, Exa for practice | Exa misses version details, may be outdated |
| Use DeepWiki for a simple API question | Use Context7 | DeepWiki is overkill, slower, less precise |
| Use Context7 for current events or news | Use Exa with date filters | Context7 doesn't have current info |
| Use Exa without date filters for fast-moving topics | Add `after:YYYY` filter | Prevents stale results |
| Use one source and stop | Chain sources for complex queries | Single sources miss context |
| Query Context7 without resolving a library ID first | Always resolve first | Unresolved queries are less precise |
| Use DeepWiki for non-GitHub or obscure repos | Try Exa first | DeepWiki coverage is limited to known repos |
| Skip quality heuristics | Evaluate results before proceeding | Poor results lead to poor answers |
| Ask Exa for "what is X" when X is a library | Use Context7 or the library's own docs | Tutorials are not API references |

---

## Integration With the Researcher Workflow

Source selection fits into the broader research process:

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│ Receive Task │────▶│ CLASSIFY query   │────▶│ SELECT source│
└──────────────┘     │ (Step 1)         │     │ (Step 2)     │
                     └──────────────────┘     └──────┬───────┘
                                                     │
                                                     ▼
                     ┌──────────────────┐     ┌──────────────┐
                     │ EVALUATE results │◀────│ EXECUTE query│
                     │ (quality heur.)  │     │ (Step 3)     │
                     └────────┬─────────┘     └──────────────┘
                              │
                     ┌────────▼─────────┐
                     │ Results good?    │
                     │ YES → return     │
                     │ NO  → chain      │
                     │       (Step 4)   │
                     └──────────────────┘
```

When returning research results, briefly note WHICH source(s) were used and WHY
— it helps the orchestrator understand the reliability of the information:

> "Found via Context7 (API reference) and Exa (real-world patterns). Cross-referenced — both agree."

---

## Rules & Guidelines

1. **Classify before you search** — A 2-second classification saves a wasted query.
2. **Resolve Context7 library IDs** — Every time. Unresolved queries are 60% less precise.
3. **Date filters on Exa for current topics** — The default search may return 3-year-old results.
4. **Chain don't settle** — If your primary source is weak, chain to another.
5. **Quality-check every result** — A bad source is worse than no source.
6. **Cross-reference critical facts** — Deprecations, security issues, breaking changes = 2+ sources.
7. **Don't use DeepWiki for API docs** — It's for architecture, not parameter lists.
8. **Don't use Exa for version-specific behavior** — It won't know about v14.3.0 edge cases.
9. **Prefer Context7 over web search for library questions** — Always. It's faster and more accurate.
10. **Note your sources** — Tell the orchestrator what you used and why.
