---
name: test-strategy-selection
description: >-
  Choose the right type of tests before writing any — unit, integration,
  contract, e2e, or static — based on risk, context, and ROI. Use before
  writing any tests to determine the appropriate testing strategy. Covers
  modern test shapes (pyramid, trophy, honeycomb), risk-based decision
  frameworks, CI/CD integration, cost/benefit analysis by test type, and
  codebase context guidance. NOT optional when planning test approach.
---

# Test Strategy Selection

## When to Use

- **Always** before writing tests — choose the right type first
- When deciding how to test a new feature, change, or system
- When evaluating existing test coverage gaps
- When a test type isn't giving you the expected ROI
- When defining the testing approach for a new project or service

---

## Modern Test Landscape

### Test Types Defined

| Type | What It Tests | Speed | Confidence | Cost |
|------|--------------|-------|-----------|------|
| **Static analysis** | Types, lint, formatting, dead code | ⚡ Instant | Low | $0 |
| **Unit** | Single function/class in isolation | ⚡ ms | Low–Medium | $ |
| **Integration** | Multiple components working together | 🐢 seconds | High | $$ |
| **Contract** | Service boundary compatibility | 🐢 seconds | Medium–High | $$ |
| **End-to-end** | Full user flow through the system | 🐌 minutes | Highest | $$$$ |

### The Shapes of Testing (Which Shape Fits Your Context)

| Shape | Ratio | Best For |
|-------|-------|----------|
| **🏛️ Pyramid** (Cohn) | 70% Unit / 20% Integration / 10% E2E | Monoliths, logic-heavy apps, traditional web apps |
| **🏆 Trophy** (Dodds) | Static + Unit + fat Integration + thin E2E | Component-driven frontends, React/Vue apps |
| **🍯 Honeycomb** (Spotify) | Many Integration + Contract, few Unit + E2E | Microservices, network-heavy architectures |
| **💎 Diamond / Skyscraper** | Heavy Integration/Service, narrow Unit + E2E | Cloud-native, API-heavy applications |

**Core insight from Martin Fowler:** The shape debate is mostly semantic. What matters is that tests are fast, reliable, and catch meaningful failures. Focus on that instead.

**From Emily Bache (2026) — Test Desiderata 2.0:**
Beyond shapes, aim for four properties:
1. **Fast** — tests run quickly
2. **Cheap** — low cost to write and maintain
3. **Predictive** — catches bugs that matter
4. **Supporting** — enables refactoring and design changes

---

## The "Push Down" Principle

> **Write tests at the lowest level that gives you the confidence you need.**

```
     Is a unit test enough?
     /                  \
    YES                  NO
     |                   |
  Write unit         Is an integration test enough?
  test                    /              \
                       YES                NO
                        |                  |
                    Write              Write E2E
                    integration         test
                    test
```

- If a **unit test** will catch the bug → write a unit test (don't write integration/E2E)
- If an **integration test** will catch it → write an integration test (don't write E2E)
- If only an **E2E test** covers the real risk → write an E2E test (don't rely on lower levels)
- Unnecessary elevation adds cost and fragility without adding confidence

---

## Decision Framework: Which Test Type When?

### By Question

| Question You're Asking | Test Type | Why |
|------------------------|-----------|-----|
| "Does this **function** do what I expect?" | **Unit** | Fast, isolated, precise |
| "Do these **components work together**?" | **Integration** | Catches interface mismatches, schema drift |
| "Is my **API contract** still compatible?" | **Contract** | Service boundaries, consumer-driven |
| "Can a **user actually do this thing**?" | **E2E** | Full-stack confidence, but expensive |
| "Is my code **well-typed** and lint-free?" | **Static** | Zero runtime cost, catches typos |
| "Is this **performance-sensitive** path fast enough?" | **Benchmark** | Measures speed, not correctness |
| "Is the **migration reversible**?" | **Integration** | Tests migration + rollback |

### By Flow Scope

| Scope | Test Type |
|-------|-----------|
| Behavior within a single function/module | Unit test |
| Behavior at the boundary of two services | Contract test |
| Behavior involving real DB, queue, or cache | Integration test (Testcontainers) |
| Behavior across the full system (UI→API→DB→external) | E2E test |
| Behavior of a critical user journey | E2E test (sparingly) |

### By Kent C. Dodds' Confidence Argument

> "Static analysis cannot give you confidence in business logic. Unit tests cannot ensure you're calling a dependency correctly. Integration tests cannot ensure you're passing the right data to your backend. E2E tests are the most capable, but at a cost."

**Solution:** Use **integration tests as the default** — they give the best confidence per dollar. E2E for critical paths only.

---

## Risk-Based Decision Framework

Score each feature or change area on two dimensions:

### Step 1: Rate the Risk

| Dimension | 1 (Low) | 2 (Medium) | 3 (High) | 4 (Critical) |
|-----------|---------|------------|----------|--------------|
| **Business Impact** | Cosmetic, rarely used | Minor feature, internal tool | Core feature, revenue-impacting | Safety-critical, financial, PII |
| **Failure Probability** | Stable code, no changes | Occasional changes, tested area | High churn, complex logic | New code, external dependencies, concurrency |

### Step 2: Calculate Risk Score

> **Risk Score = Business Impact × Failure Probability**

| Score | Category | Testing Requirement |
|-------|----------|-------------------|
| **1-4** | 🟢 Low | Minimal — smoke tests, unit only |
| **5-6** | 🟡 Medium | Standard — unit + integration |
| **7-9** | 🟠 High | Thorough — unit + integration + contract |
| **10-16** | 🔴 Critical | Extensive — unit + integration + contract + E2E |

### Step 3: Allocate Effort

| Category | Effort | Examples |
|----------|--------|---------|
| 🔴 Critical | 40% of test budget | Payment processing, authentication, data integrity |
| 🟠 High | 30% | Search, recommendations, user management |
| 🟡 Medium | 20% | Profile pages, notifications, reporting |
| 🟢 Low | 10% | Admin panels, internal tools, logging |

---

## Cost/Benefit Analysis

| Dimension | Unit | Integration | Contract | E2E |
|-----------|------|-------------|----------|-----|
| Execution speed | ⚡ ms | 🐢 seconds | 🐢 seconds | 🐌 minutes |
| Write cost | $ Low | $$ Medium | $$ Medium | $$$$ High |
| Maintenance cost | $ Low | $$ Medium | $ Low | $$$$ High |
| Debugging signal | ✅ Precise | ✅ Good | ✅ Good | ❌ Noisy |
| Flakiness | 🟢 Very low | 🟢 Low | 🟢 Very low | 🔴 High |
| Catches | Logic bugs | Interface/DB bugs | API incompatibility | System wiring issues |

### Key Economic Insights

- **Unit tests** are ~100× cheaper to write and ~100× faster to run than E2E tests (Mike Cohn)
- **Integration tests** give the best ROI for most modern applications — they catch ~60%+ of production bugs that unit tests miss, at a fraction of E2E cost
- **The most expensive test is the one written at the wrong level** — too low (misses bugs) or too high (slow, brittle)
- **Contract tests** are the cheapest way to verify cross-service compatibility — no need to deploy both services

---

## Strategy by Codebase Context

### Greenfield (New Project)
- Start with **70/20/10 pyramid** as default
- Invest in test infrastructure early (Testcontainers, CI pipeline, test sharding)
- Establish contract tests from day one if microservices are planned
- Write tests alongside code (TDD/BDD for domain logic)

### Legacy Code (Untested, High Debt)
1. **Write a test before every bug fix** — regression safety net
2. **Write a test before every refactor** — characterization tests capture current behavior
3. **Write integration tests first** — they give more value per test than unit tests when boundaries are unclear
4. **Characterization testing**: Test what the code *does*, not what it *should do*

> "The first useful tests on a legacy system were integration tests that fed data through the full pipeline."

### Monolith
- Classic pyramid works well — heavy unit tests, integration tests for module boundaries
- E2E tests are simpler (single deployable, one process)
- ⚠️ Danger: E2E tests can balloon because they're "easy" to write — **resist this**
- Modular monolith: treat internal module boundaries with contract-test rigor

### Microservices
- **Pyramid focus flips**: Unit + Contract tests dominate; E2E is minimized
- **Contract testing is the linchpin** — verifies API compatibility without deploying both services
- Use **consumer-driven contracts** (Pact) to detect breaking changes pre-deployment
- Recommended distribution:
  - 70% Unit (per service)
  - 20% Contract (cross-service API boundaries)
  - 5% Integration (service + real database)
  - 5% E2E (critical user journeys only)

### Hybrid (Monolith → Microservices Migration)
- Use the **Strangler Pattern**: extract services incrementally
- Feature toggles create testing complexity — verify both toggle-on and toggle-off states
- Contract testing protects new microservice boundaries
- Integration tests verify sync between old monolith and extracted services
- ⚡ 68% of successful migrations used contract testing; only 22% of failed ones did

---

## CI/CD Integration

### Staged Pipeline (Progressive Confidence)

```
Commit       → Unit tests + lint + static analysis     → 60% confidence (< 2 min)
PR merge     → + Integration tests + contract tests     → 80% confidence (5-15 min)
Staging      → + E2E tests (critical paths)             → 90% confidence (15-30 min)
Canary       → 5% traffic + monitoring                  → 95% confidence
Full roll    → 100% traffic                             → 99% confidence
```

### Test Selection by Trigger

| Trigger | Tests to Run |
|---------|-------------|
| Every commit (branch) | Lint, unit, type check |
| Pull request open/update | + Integration, impact-analyzed regression |
| Merge to main | + Contract, component tests |
| Deploy to staging | + E2E (critical paths) |
| Deploy to production | + Smoke tests |
| Nightly | + Full E2E suite, load, security |
| Pre-release | + Manual exploratory testing |

### Quality Gates

- **Hard gates** 🚫: Pipeline fails — test failures, critical security vulns, build errors
- **Soft gates** ⚠️: Warning logged — coverage drops, medium-severity findings
- Reserve hard gates for issues that directly impact production safety

---

## Coverage Targets (by Test Type)

Use these as signals, not goals:

| Code Type | Coverage Target | Test Level |
|-----------|----------------|------------|
| Business logic modules | 90%+ branch coverage | Unit |
| API handlers | 80%+ line coverage | Unit + Integration |
| Utility/pure functions | 95%+ | Unit |
| UI components (critical) | 60%+ | Integration (component tests) |
| Generated code | 0% (test through integration) | Integration |
| Database migrations | 0% unit tests (test by running them) | Integration |

### Speed Budgets

| Layer | Max Total Time | Per-Test Budget |
|-------|---------------|-----------------|
| Unit tests | < 30 sec | < 10ms |
| Integration tests | < 3 min | 50-500ms |
| E2E tests | < 10 min | 2-30s |

---

## Rules

1. **Push down** — write tests at the lowest level that gives confidence
2. **Don't write E2E tests for things unit tests can cover** — they're slow and brittle
3. **Mock external dependencies in unit tests**; use real ones in integration tests
4. **If unsure, start with unit tests** — add integration tests where units pass but the system still breaks
5. **State your strategy explicitly** before writing tests (you're choosing a level)
6. **Contract tests over E2E for service boundaries** — cheaper, faster, less flaky
7. **Integration tests are the default for most modern apps** — best confidence per dollar
8. **Revisit the strategy quarterly** — as the codebase evolves, the optimal balance shifts
9. **Coverage is a signal, NOT a goal** — 100% coverage with no assertions is "code tourism"
10. **The most expensive test is the one at the wrong level** — invest time getting the strategy right
