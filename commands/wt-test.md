---
model: claude-sonnet-4-6
---

# /wt-test — Generate and run unit tests

You are acting as a WordPress plugin QA engineer specializing in PHPUnit.

## Instructions

Invoke the **wp-plugin-development** skill before generating any test files.

---

### Step 0: Scaffold test structure if missing

Read `CLAUDE.md` to get the plugin folder name. All test files live **inside the plugin folder** so paths resolve correctly and the release zip can exclude them cleanly.

```bash
PLUGIN_DIR=$(grep "Git repo" CLAUDE.md | sed 's/.*: //')
PLUGIN_FOLDER=$(basename "$PLUGIN_DIR")
```

Check whether the test scaffold exists inside the plugin folder:

```bash
ls {plugin-folder}/tests/unit
ls {plugin-folder}/tests/integration
ls {plugin-folder}/tests/bootstrap.php
ls {plugin-folder}/phpunit.xml
```

If missing — create them:

```bash
mkdir -p {plugin-folder}/tests/unit {plugin-folder}/tests/integration
```

If `{plugin-folder}/tests/bootstrap.php` does not exist, create it:

```php
<?php
/**
 * PHPUnit bootstrap file.
 *
 * @package {plugin-slug}
 */

// Composer autoloader (relative to plugin root)
require_once dirname( __DIR__ ) . '/vendor/autoload.php';

// Load Brain Monkey
\Brain\Monkey\setUp();

// Define WordPress constants needed by the plugin
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', dirname( __DIR__, 2 ) . '/' );
}
if ( ! defined( 'WPINC' ) ) {
	define( 'WPINC', 'wp-includes' );
}
```

If `{plugin-folder}/phpunit.xml` does not exist, create it:

```xml
<?xml version="1.0"?>
<phpunit
    bootstrap="tests/bootstrap.php"
    colors="true"
    convertErrorsToExceptions="true"
    convertNoticesToExceptions="true"
    convertWarningsToExceptions="true"
>
    <testsuites>
        <testsuite name="Unit">
            <directory>tests/unit</directory>
        </testsuite>
        <testsuite name="Integration">
            <directory>tests/integration</directory>
        </testsuite>
    </testsuites>
    <coverage>
        <include>
            <directory suffix=".php">includes</directory>
            <directory suffix=".php">admin</directory>
        </include>
    </coverage>
</phpunit>
```

> ⚠️ `tests/` lives inside the plugin folder — excluded from release zip by `wt-release` (`--exclude='tests/'`). Never commit test files to the plugin's production zip.

Show:
```
✅ {plugin-folder}/tests/unit/ ready
✅ {plugin-folder}/tests/integration/ ready
✅ {plugin-folder}/tests/bootstrap.php ready
✅ {plugin-folder}/phpunit.xml ready
```

All subsequent steps run from inside `{plugin-folder}/`.

---

### Step 1: Parallel test audit (sub-agents)

Launch the following sub-agents **simultaneously** using the Agent tool:

**Sub-agent A — Existing test inventory (`code-explorer` agent — haiku, effort: medium):**
- Read all files in `{plugin-folder}/tests/unit/` and `{plugin-folder}/tests/integration/`
- Map each test file to its corresponding source class in `{plugin-folder}/includes/`
- Return: list of tested classes + example test structure to follow

**Sub-agent B — Untested class discovery (`code-explorer` agent — haiku, effort: medium):**
- Scan all PHP classes in `{plugin-folder}/includes/`
- Cross-reference against Sub-agent A results
- Return: list of classes with NO test coverage, with their public method signatures

Wait for both sub-agents before proceeding.

---

### Step 2: Generate missing tests

For each untested class identified by Sub-agent B, create `{plugin-folder}/tests/unit/class-{slug}-test.php`:

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
cd {plugin-folder} && ./vendor/bin/phpunit --testdox --colors=always 2>&1
```

---

### Step 4: Coverage report

```bash
cd {plugin-folder} && ./vendor/bin/phpunit --coverage-text --colors=never 2>&1 | tail -40
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
