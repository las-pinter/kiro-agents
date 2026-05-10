---
name: test-case-structure
description: >-
  Language-agnostic structure, naming conventions, and rules for writing clear,
  maintainable test cases. Use this skill when writing ANY test — unit,
  integration, or e2e — in any programming language. Covers naming patterns,
  AAA/GWT structure, test data management, assertion strategies, parameterized
  testing, test doubles, and flaky test prevention. Always load before writing
  or reviewing test code.
---

# Test Case Structure

## When to Use

- When writing any test case — unit, integration, or e2e
- When reviewing test code for quality and maintainability
- When establishing testing conventions for a new project
- When refactoring existing tests to improve clarity and reliability

---

## Universal Principles

### 1. Describe Behavior, Not Implementation

Test names describe WHAT the code does, not HOW it does it.

**Behavior** = observable outcome meaningful to users or domain experts
**Implementation** = internal mechanics, method calls, data structures

❌ **Bad** (implementation-focused):
- `callsDatabaseQuery`
- `loopsThroughArray`
- `test_uses_cache_first`
- `verifyServiceIsCalled`

✅ **Good** (behavior-focused):
- `returnsUserWhenIdExists`
- `returnsEmptyListWhenNoResultsFound`
- `ReturnsNotFoundForMissingResource`
- `rejectsPaymentWhenBalanceInsufficient`

### 2. Three Essential Components

Every test name should answer three questions:

- **Context** — What state, input, or scenario?
- **Action** — What behavior is triggered?
- **Outcome** — What should happen?

### 3. Readability Over Convention

Test names are documentation. Prioritize clarity over brevity or rigid patterns.
If a longer name is clearer, use it. If a shorter name is still unambiguous, use that.

---

## Naming Patterns (Language-Agnostic)

### Pattern 1: Given-When-Then

Best for: Complex scenarios with multiple preconditions.

```
// JavaScript / TypeScript
it('returns error when cart is empty')

# Python
test_given_empty_cart_when_checkout_then_raises_error

// Java
givenEmptyCart_whenCheckout_thenRaisesError()

// C#
GivenEmptyCart_WhenCheckout_ThenRaisesError()

// Rust
fn empty_cart_checkout_raises_error()

// Go
func TestGivenEmptyCart_WhenCheckout_RaisesError(t *testing.T)
```

### Pattern 2: Condition-Outcome

Best for: Simple, single-condition scenarios.

```
// JavaScript
it('rejects payment when balance insufficient')

# Python
test_insufficient_balance_rejects_payment

// Java
insufficientBalance_rejectsPayment()

// C#
InsufficientBalance_RejectsPayment()
```

### Pattern 3: Descriptive / BDD Style

Best for: Complex domains where readability matters most.

```
// JavaScript / TypeScript
describe('User Login', () => {
  it('succeeds with valid credentials')
})

# Python (with pytest-describe or nested classes)
class TestLogin:
    def test_succeeds_with_valid_credentials(self): ...

// Java (@DisplayName)
@DisplayName("Login succeeds with valid credentials")
loginSucceedsWithValidCredentials()
```

### Pattern 4: Nested Context (Recommended for Complex Flows)

Eliminates redundancy by grouping related scenarios:

```
describe('Payment Processing')
  describe('when credit card is valid')
    it('completes transaction successfully')
    it('sends confirmation email')
  describe('when credit card is expired')
    it('rejects the transaction')
    it('returns descriptive error message')
  describe('when credit card is stolen')
    it('flags for fraud review')
    it('notifies security team')
```

### What to Avoid in Names

- **Fluff words**: "Correctly", "Properly", "Valid" (unless part of exact scenario)
- **Redundant prefixes**: "Test" (unless framework requires it)
- **Implementation details**: exception types, method names, variable names
- **Testing multiple scenarios** in one test (split into separate tests)
- **Magic values** without context (`test_returns_42` instead of `test_returns_max_items_per_page`)

---

## Test Structure

### Arrange-Act-Assert (AAA)

Universal structure for any test, any language:

```
test: [name]
  // Arrange
  [set up test data and preconditions]

  // Act
  [execute the behavior under test]

  // Assert
  [verify the outcome]
```

**Key rules:**
- One `Act` per test — multiple actions make failure diagnosis ambiguous
- `Arrange` sets up only what's needed for THIS test — no more, no less
- `Assert` verifies the outcome, not intermediate state
- Separate phases with blank lines or comments for readability

### Given-When-Then (GWT)

Semantically identical to AAA, but framed for behavior:

```
Scenario: [name]
  Given [preconditions]
  When  [action]
  Then  [outcome]
```

| AAA | GWT |
|-----|-----|
| Arrange | Given |
| Act | When |
| Assert | Then |

**Use AAA** for developer-facing unit tests. **Use GWT** for stakeholder-facing scenarios (BDD, acceptance tests).

### Good Example (AAA)

```
test: calculateTotalWithDiscount
  // Arrange
  cart = createCart(items: [item1, item2])
  discount = 0.1

  // Act
  total = cart.calculateTotal(discount)

  // Assert
  expect(total).equals(90.0)
```

### Bad Example (Multiple Behaviors)

```
test: cart_operations
  cart.addItem(item1)
  expect(cart.count).equals(1)      // Testing add
  cart.removeItem(item1)
  expect(cart.count).equals(0)      // Testing remove
  total = cart.calculateTotal()
  expect(total).equals(0)           // Testing calculate
```

**Split into three tests:**
- `addingItemIncreasesCount`
- `removingItemDecreasesCount`
- `emptyCartTotalIsZero`

---

## Test Data Management

### Three Core Patterns

**1. Fixtures** — Static data (JSON, SQL, YAML) loaded before tests
- ✅ Good for: Reference data, read-only tests, snapshot testing
- ❌ Risk: Hidden coupling, brittle when schema changes
- 📏 Rule: Only for data tests READ but never MODIFY

**2. Factories** — Functions that generate data on demand
- ✅ Good for: Each test creates its own data; sensible defaults
- ✅ Key: `factory.user({ role: 'admin' }).build()` or `.create(db)`
- 📏 Rule: Defaults must be valid — calling with no overrides must pass all validation

**3. Builders** — Fluent interface for complex construction
```python
UserBuilder()
    .with_name("Alice")
    .with_role("admin")
    .with_permissions(["read", "write"])
    .build()
```
- ✅ Good for: Objects with many optional fields; readability
- 📏 Rule: Immutable pattern prevents shared state between tests

### Test Data Golden Rules

- **Each test creates its own data** — never depend on data from other tests
- **Factory defaults must be valid** — calling with no overrides must pass validation
- **Override only what matters** for the specific test scenario
- **Use unique values** for unique-constrained fields (timestamp/UUID suffix)
- **Clean up between tests** — transaction rollback is ideal
- **Keep factories next to tests** — test infrastructure, not application code
- **Use fixtures + factories together** — fixtures for reference data, factories for test-specific data

### Anti-Patterns
- ❌ Hardcoded IDs (`id = 1`) — break when database resets
- ❌ Shared global seed files — invisible dependencies between tests
- ❌ Over-seeding in `beforeEach` / `setup` — every test becomes slow and unclear
- ❌ Production data in tests — PII/legal risk; use Faker for synthetic data
- ❌ Object Mother without overrides — brittle coupling

---

## Assertion Patterns

### Core Principles

1. **Assert the exact desired behavior** — not more (brittle), not less (misses regressions)
2. **One assertion per logical concept** — multiple asserts OK if verifying different aspects of the SAME behavior
3. **Assert requirements, not implementation** — test should survive refactoring
4. **Use the most specific assertion** — `assertEquals(expected, actual)` over `assertTrue(result == expected)`
5. **Provide custom failure messages** — especially in parameterized contexts
6. **Use fluent assertion libraries** — AssertJ, Hamcrest, Shouldly for readability and helpful failure messages
7. **Group related assertions** with soft assertions / `assertAll` — reports ALL failures, not just the first

### Good vs Bad Assertions

❌ **Bad:**
```python
assert result == True                     # Too vague
assert len(items) > 0                     # Doesn't verify content
assert response.status_code == 200        # Doesn't verify body
```

✅ **Good:**
```python
assert result.is_success == True          # Named property
assert items == [expected_item]           # Verifies exact content
assert response.json() == {'id': 1}       # Verifies body too
```

---

## Parameterized Testing

### When to Use
- Same logic across multiple input/output pairs
- Edge case coverage (null, empty, boundary, extreme values)
- Combinatorial scenarios (multiple parameters)
- Property-based testing (universal properties across many inputs)

### Best Practices
- **Keep sources close** — inline data for simple cases; external only when data is reused
- **Avoid logic in data providers** — providers should be "dumb" data, not computation
- **Use descriptive IDs/names** for each parameter set
- **Test one concept per parameterized test** — don't cram unrelated scenarios
- **Include null/empty/boundary** as explicit parameter cases

### Framework Patterns

| Framework | Simple Cases | Complex Cases |
|-----------|-------------|---------------|
| **pytest** | `@pytest.mark.parametrize("input,expected", [(1,2), (3,4)])` | `pytest.param(1, 2, id="first_case")` |
| **JUnit 5** | `@CsvSource({"1,2", "3,4"})` | `@MethodSource("dataProvider")` |
| **xUnit.net** | `[InlineData(1, 2)]` | `[MemberData(nameof(DataMethod))]` |
| **Jest** | `it.each([[1, 2], [3, 4]])` | `it.each` with template literals |

### Pitfalls to Avoid
- ❌ **Zip function silently drops cases** when arrays differ in length
- ❌ **Enum-driven testing leads to gaps** — enums may include cases that don't map to distinct behavior
- ❌ **Logic in test body** to handle different parameter sets differently (if/switch on parameter)
- ❌ **Reduced readability** — when data is extracted far from the test body

---

## Test Doubles (Mocks, Stubs, Fakes)

### The Taxonomy (Gerard Meszaros)

| Type | Purpose | Behavior | Verifies |
|------|---------|----------|----------|
| **Dummy** | Fills parameter lists | None — not called | Nothing |
| **Fake** | Working but simplified implementation | Yes | State after interaction |
| **Stub** | Provides canned answers | Yes (returns) | Indirect inputs |
| **Spy** | Records calls for later verification | Yes (records) | Indirect outputs |
| **Mock** | Pre-programmed expectations | Yes (expects) | Behavior (was it called correctly?) |

### When to Use Test Doubles

✅ **DO use** for:
- External systems (databases, HTTP APIs, filesystems, message queues)
- Slow dependencies (ML models, large file processing)
- Non-deterministic services (random, time-based, network)
- Things not yet built (parallel development)

❌ **DO NOT use** for:
- Value objects (money, dates, coordinates) — use real instances
- Simple domain logic — test with real objects
- Immutable data structures

### Over-Mocking Is the #1 Anti-Pattern

- Couples tests to implementation details
- Makes refactoring painful — change internal structure, break tests
- Creates false confidence — tests pass even when real interaction fails

**Prefer order:** Fakes → Stubs/Spies → Mocks. Use mocks only when the interaction contract matters.

---

## Language-Specific Adaptations

Follow language conventions while maintaining universal principles:

| Language | Naming Convention | Structure Pattern |
|----------|-------------------|-------------------|
| **Python** | `test_behavior_when_context` | AAA with blank-line separation |
| **JavaScript/TS** | `it('behavior when context')` or `it.each` | `describe`/`it` blocks |
| **Java** | `@DisplayName("behavior")` + `behaviorWhenContext()` | JUnit 5 with `assertAll` |
| **C#** | `Behavior_Context_Outcome()` | xUnit `[Fact]` / `[Theory]` |
| **Go** | `TestBehaviorWhenContext(t *testing.T)` | Table-driven tests with sub-tests |
| **Rust** | `fn behavior_when_context()` | `#[test]` with nested `mod` blocks |
| **Kotlin** | `"behavior when context" { ... }` | String test names with Spek/Kotest |

---

## Flaky Test Prevention

### Root Causes (Ranked by Frequency)

| Cause | Frequency | Fix |
|-------|-----------|-----|
| **Async wait issues** | ~45% | Replace `sleep()` with condition-based waits + explicit timeouts |
| **Shared state pollution** | Common | Each test creates its own data; transaction rollback |
| **Test order dependencies** | Common | Randomize test order; each test self-contained |
| **Concurrency problems** | Common | Proper locking; test isolation |
| **Environment drift** | Less common | Containerize; pin versions |
| **Non-deterministic data** | Common | Fixed seeds; mock time/random |

### Prevention Rules
1. **No `sleep()` calls** — ever. All waits must be condition-based with explicit timeouts
2. **Each test creates its own data** — shared state is the #2 cause of flakiness
3. **Randomize test order** — at least weekly; fix any that break immediately
4. **Containerize environments** — pin OS, language runtime, dependency versions
5. **Mock external services** — unit/integration tests shouldn't depend on network availability
6. **Auto-waiting frameworks** (Playwright, Cypress) handle most async flakiness

### Quarantine Protocol
1. Move flaky test to **non-blocking quarantine suite**
2. Assign **owner + two-week deadline** to fix
3. Track flakiness rate as a **team metric**
4. If not fixed in deadline: **delete it** (a test nobody trusts is a liability)

---

## Test Code Review Checklist

When reviewing test code, check for:

- [ ] Does the test exist? — every new function/endpoint/component needs a test
- [ ] Is the structure clear? — AAA pattern visible, phases delineated
- [ ] Is the name descriptive? — explains scenario + outcome without reading the body
- [ ] Are tests independent? — no shared mutable state, no order dependencies
- [ ] Are assertions meaningful? — specific matchers, not truthy checks
- [ ] Edge cases covered? — empty, null, boundary, error paths, not just happy path
- [ ] No implementation detail testing? — tests behavior, not internal calls
- [ ] No over-mocking? — mocks for external boundaries only
- [ ] No sleeps/hardcoded waits? — all waits are condition-based
- [ ] Test data isolated? — each test creates its own; no shared fixtures for mutable data
- [ ] Regression test for bug fixes? — bug fix PR includes a test that would have caught it
- [ ] Coverage threshold met? — new code at 80%+; overall coverage never decreases
