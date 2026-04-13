#!/usr/bin/env bash
# new-plugin.sh — Scaffold a new WordPress/WooCommerce plugin anywhere
# Usage: bash ~/.claude/scripts/new-plugin.sh

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  NEW PLUGIN SCAFFOLD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -p "Plugin name (e.g. My Awesome Plugin): " PLUGIN_NAME
read -p "Plugin slug (e.g. my-awesome-plugin): " PLUGIN_SLUG
read -p "Plugin prefix/constant (e.g. MAP): " PLUGIN_PREFIX
read -p "Author name: " AUTHOR_NAME
read -p "Author URI: " AUTHOR_URI
read -p "Jira project key (e.g. MAP): " JIRA_KEY
read -p "Bitbucket repo (e.g. org/my-awesome-plugin): " BB_REPO
read -p "Minimum WP version (default 6.0): " MIN_WP
read -p "Minimum WC version (default 8.0): " MIN_WC
read -p "Destination path (default: /Applications/MAMP/htdocs/sourcetree/My Plugins/$PLUGIN_SLUG): " DEST_INPUT

MIN_WP="${MIN_WP:-6.0}"
MIN_WC="${MIN_WC:-8.0}"
DEST="${DEST_INPUT:-/Applications/MAMP/htdocs/sourcetree/My Plugins/$PLUGIN_SLUG}"

echo ""
echo "  Creating plugin at: $DEST"
echo ""

mkdir -p "$DEST"/{includes/admin,includes/woocommerce,templates,assets/css,assets/js,tests/unit,tests/integration}

PREFIX_LOWER=$(echo "$PLUGIN_PREFIX" | tr '[:upper:]' '[:lower:]')

# ── Main plugin file ──────────────────────────────
cat > "$DEST/$PLUGIN_SLUG.php" << PHPEOF
<?php
/**
 * Plugin Name:       $PLUGIN_NAME
 * Plugin URI:        $AUTHOR_URI
 * Description:       $PLUGIN_NAME plugin.
 * Version:           1.0.0
 * Author:            $AUTHOR_NAME
 * Author URI:        $AUTHOR_URI
 * License:           GPL v2 or later
 * License URI:       https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain:       $PLUGIN_SLUG
 * Domain Path:       /languages
 * Requires at least: $MIN_WP
 * Requires PHP:      8.0
 * WC requires at least: $MIN_WC
 * WC tested up to:   9.0
 *
 * @package ${PLUGIN_PREFIX}
 */

defined( 'ABSPATH' ) || exit;

define( '${PLUGIN_PREFIX}_VERSION', '1.0.0' );
define( '${PLUGIN_PREFIX}_PLUGIN_DIR', plugin_dir_path( __FILE__ ) );
define( '${PLUGIN_PREFIX}_PLUGIN_URL', plugin_dir_url( __FILE__ ) );

if ( file_exists( ${PLUGIN_PREFIX}_PLUGIN_DIR . 'vendor/autoload.php' ) ) {
    require_once ${PLUGIN_PREFIX}_PLUGIN_DIR . 'vendor/autoload.php';
}

function ${PREFIX_LOWER}_init(): void {
    add_action(
        'before_woocommerce_init',
        function () {
            if ( class_exists( \Automattic\WooCommerce\Utilities\FeaturesUtil::class ) ) {
                \Automattic\WooCommerce\Utilities\FeaturesUtil::declare_compatibility( 'custom_order_tables', __FILE__, true );
            }
        }
    );
    ${PLUGIN_PREFIX}_Plugin::get_instance();
}
add_action( 'plugins_loaded', '${PREFIX_LOWER}_init' );

register_activation_hook( __FILE__, array( '${PLUGIN_PREFIX}_Plugin', 'activate' ) );
register_deactivation_hook( __FILE__, array( '${PLUGIN_PREFIX}_Plugin', 'deactivate' ) );
register_uninstall_hook( __FILE__, array( '${PLUGIN_PREFIX}_Plugin', 'uninstall' ) );
PHPEOF

# ── Main class ───────────────────────────────────
cat > "$DEST/includes/class-${PREFIX_LOWER}-plugin.php" << PHPEOF
<?php
/**
 * Main plugin class.
 *
 * @package ${PLUGIN_PREFIX}
 */

defined( 'ABSPATH' ) || exit;

/**
 * Class ${PLUGIN_PREFIX}_Plugin
 */
class ${PLUGIN_PREFIX}_Plugin {

    private static ?self \$instance = null;

    public static function get_instance(): static {
        if ( null === static::\$instance ) {
            static::\$instance = new static();
        }
        return static::\$instance;
    }

    private function __construct() {
        \$this->init_hooks();
    }

    private function init_hooks(): void {
        add_action( 'init', array( \$this, 'load_textdomain' ) );
    }

    public function load_textdomain(): void {
        load_plugin_textdomain( '$PLUGIN_SLUG', false, dirname( plugin_basename( ${PLUGIN_PREFIX}_PLUGIN_DIR . '$PLUGIN_SLUG.php' ) ) . '/languages' );
    }

    public static function activate(): void {
        flush_rewrite_rules();
    }

    public static function deactivate(): void {
        flush_rewrite_rules();
    }

    public static function uninstall(): void {
        delete_option( '${PREFIX_LOWER}_settings' );
    }
}
PHPEOF

# ── composer.json ─────────────────────────────────
cat > "$DEST/composer.json" << JSON
{
    "name": "$(echo $AUTHOR_NAME | tr '[:upper:]' '[:lower:]' | tr ' ' '-')/$PLUGIN_SLUG",
    "description": "$PLUGIN_NAME",
    "type": "wordpress-plugin",
    "require": { "php": ">=8.0" },
    "require-dev": {
        "phpunit/phpunit": "^10.0",
        "phpstan/phpstan": "^1.0",
        "szepeviktor/phpstan-wordpress": "^1.0",
        "php-stubs/woocommerce-stubs": "^9.0",
        "squizlabs/php_codesniffer": "^3.0",
        "wp-coding-standards/wpcs": "^3.0",
        "dealerdirect/phpcodesniffer-composer-installer": "^1.0",
        "yoast/phpunit-polyfills": "^2.0"
    },
    "autoload": { "classmap": ["includes/"] },
    "config": {
        "allow-plugins": {
            "dealerdirect/phpcodesniffer-composer-installer": true
        }
    }
}
JSON

# ── phpunit.xml ───────────────────────────────────
cat > "$DEST/phpunit.xml" << XML
<?xml version="1.0"?>
<phpunit bootstrap="tests/bootstrap.php" colors="true">
    <testsuites>
        <testsuite name="unit"><directory>tests/unit</directory></testsuite>
        <testsuite name="integration"><directory>tests/integration</directory></testsuite>
    </testsuites>
    <coverage><include><directory suffix=".php">includes</directory></include></coverage>
</phpunit>
XML

# ── phpstan.neon ──────────────────────────────────
cat > "$DEST/phpstan.neon" << NEON
parameters:
    level: 6
    paths:
        - includes/
    bootstrapFiles:
        - vendor/php-stubs/wordpress-stubs/wordpress-stubs.php
        - vendor/php-stubs/woocommerce-stubs/woocommerce-stubs.php
NEON

# ── .phpcs.xml ────────────────────────────────────
cat > "$DEST/.phpcs.xml" << XML
<?xml version="1.0"?>
<ruleset name="${PLUGIN_NAME}">
    <file>includes/</file>
    <file>${PLUGIN_SLUG}.php</file>
    <arg name="extensions" value="php"/>
    <rule ref="WordPress">
        <exclude name="WordPress.Files.FileName"/>
    </rule>
    <rule ref="WordPress.WP.I18n">
        <properties>
            <property name="text_domain" type="array" value="$PLUGIN_SLUG"/>
        </properties>
    </rule>
</ruleset>
XML

# ── tests/bootstrap.php ───────────────────────────
cat > "$DEST/tests/bootstrap.php" << PHPEOF
<?php
/**
 * PHPUnit bootstrap.
 *
 * @package ${PLUGIN_PREFIX}
 */

\$_tests_dir = getenv( 'WP_TESTS_DIR' ) ?: rtrim( sys_get_temp_dir(), '/\\\\' ) . '/wordpress-tests-lib';

if ( ! file_exists( "\$_tests_dir/includes/functions.php" ) ) {
    echo "WP test library not found at \$_tests_dir\n";
    exit( 1 );
}

require_once "\$_tests_dir/includes/functions.php";

function ${PREFIX_LOWER}_manually_load_plugin(): void {
    require dirname( __DIR__ ) . '/$PLUGIN_SLUG.php';
}
tests_add_filter( 'muplugins_loaded', '${PREFIX_LOWER}_manually_load_plugin' );

require "\$_tests_dir/includes/bootstrap.php";
PHPEOF

# ── .gitignore ────────────────────────────────────
cat > "$DEST/.gitignore" << IGNORE
/vendor/
/node_modules/
/build/
*.zip
.DS_Store
IGNORE

# ── CLAUDE.md (minimal — plugin identity only) ────
cat > "$DEST/CLAUDE.md" << MDEOF
# Plugin: $PLUGIN_NAME

## Identity
- Slug: $PLUGIN_SLUG
- Prefix: $PLUGIN_PREFIX
- Min WP: $MIN_WP | Min WC: $MIN_WC
- Jira Project Key: $JIRA_KEY
- Bitbucket Repo: $BB_REPO

## Branch naming
- feature/${JIRA_KEY}-123-description
- fix/${JIRA_KEY}-123-description
- hotfix/${JIRA_KEY}-123-description

## Workflow
Global commands: /prd /implement /review /test /qa /commit /release
Global scripts + hooks: ~/.claude/scripts/
MDEOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Plugin scaffolded at: $DEST"
echo ""
echo "  Next steps:"
echo "  1. cd \"$DEST\""
echo "  2. git init && git remote add origin <bitbucket-url>"
echo "  3. composer install"
echo "  4. Open Claude Code here, write PRD.md, then run /prd"
echo ""
echo "  To symlink into a Local Site for testing:"
echo "  ln -s \"$DEST\" \"/Users/manikandang/Local Sites/<site>/app/public/wp-content/plugins/$PLUGIN_SLUG\""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
