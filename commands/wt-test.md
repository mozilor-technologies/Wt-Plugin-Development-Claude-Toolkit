---
model: claude-sonnet-4-6
---

# /wt-test — Generate and run unit tests

You are acting as a WordPress plugin QA engineer specializing in PHPUnit.

## Instructions

Invoke the **wp-plugin-development** skill before generating any test files.

---

### Step 1: Parallel test audit (sub-agents)

Launch the following sub-agents **simultaneously** using the Agent tool:

**Sub-agent A — Existing test inventory (`code-explorer` agent — haiku, effort: medium):**
- Read all files in `tests/unit/` and `tests/integration/`
- Map each test file to its corresponding source class in `includes/`
- Return: list of tested classes + example test structure to follow

**Sub-agent B — Untested class discovery (`code-explorer` agent — haiku, effort: medium):**
- Scan all PHP classes in `includes/`
- Cross-reference against Sub-agent A results
- Return: list of classes with NO test coverage, with their public method signatures

Wait for both sub-agents before proceeding.

---

### Step 2: Generate missing tests

For each untested class identified by Sub-agent B, create `tests/unit/class-{slug}-test.php`:

```php
<?php
/**
 * Tests for ClassName
 *
 * @package PluginSlug
 */

class Test_ClassName extends WP_UnitTestCase {

    /**
     * @var ClassName
     */
    private $instance;

    public function setUp(): void {
        parent::setUp();
        $this->instance = new ClassName();
    }

    public function tearDown(): void {
        parent::tearDown();
    }

    /**
     * Test happy path — returns expected value
     */
    public function test_method_name_returns_expected_value() { ... }

    /**
     * Test edge case — empty input handled correctly
     */
    public function test_method_name_with_empty_input() { ... }

    /**
     * Test edge case — invalid input returns false or WP_Error
     */
    public function test_method_name_with_invalid_input() { ... }
}
```

**For WooCommerce features**, mock WC objects using:
- `WC_Helper_Product::create_simple_product()`
- `WC_Helper_Product::create_variation_product()`
- `WC_Helper_Order::create_order()`

**Test coverage requirements per class:**
- Every public method has at least one test
- Happy path tested
- Edge cases: empty input, null, invalid types
- WooCommerce-specific: out of stock, variable products, missing data

---

### Step 3: Run the full test suite

```bash
./vendor/bin/phpunit --testdox --colors=always 2>&1
```

---

### Step 4: Coverage report

```bash
./vendor/bin/phpunit --coverage-text --colors=never 2>&1 | tail -40
```

---

### Step 5: Report

```
## Test Report — [date] — [Plugin Name]

Tests:    X passed, Y failed, Z skipped
Coverage: X% lines, Y% methods

New test files generated:
  [list]

Failing tests:
  [test name — reason — file:line]
```

- If tests fail → Claude fixes the implementation or the test, re-runs until green
- Target coverage: ≥ 70%
- Do not mark passing until all tests are green
