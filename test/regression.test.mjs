/**
 * Regression tests for the BauDi Portal-App build artifact.
 *
 * These tests run after `ant dist` to verify that the generated XAR package
 * is correct and contains all expected files and metadata.
 */
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const DIST_DIR = join(ROOT, 'dist');

// Read build properties to get expected values
const BUILD_PROPS = readFileSync(join(ROOT, 'build.properties'), 'utf8');
function getProp(key) {
    const match = BUILD_PROPS.match(new RegExp(`^${key}=(.+)$`, 'm'));
    return match ? match[1].trim() : null;
}
const APP_NAME = getProp('project.app');       // baudiApp
const APP_VERSION = getProp('project.version'); // 1.1.0
const APP_URL = getProp('project.url');         // https://github.com/...

/** Returns the path to the first *.xar file found in dist/, or null. */
function findXar() {
    if (!existsSync(DIST_DIR)) return null;
    const files = readdirSync(DIST_DIR).filter(f => f.endsWith('.xar'));
    return files.length > 0 ? join(DIST_DIR, files[0]) : null;
}

/**
 * Lists all file paths inside the XAR (which is a ZIP archive).
 * Uses `unzip -Z1` for a clean, one-filename-per-line listing.
 * Arguments are passed as an array to avoid shell injection.
 */
function listXarContents(xarPath) {
    const output = execFileSync('unzip', ['-Z1', xarPath], { encoding: 'utf8' });
    return output.trim().split('\n').map(f => f.trim()).filter(Boolean);
}

/**
 * Reads and returns the text content of a file stored inside the XAR.
 * Arguments are passed as an array to avoid shell injection.
 */
function readXarFile(xarPath, filename) {
    return execFileSync('unzip', ['-p', xarPath, filename], { encoding: 'utf8' });
}

// ---------------------------------------------------------------------------

describe('Regression Tests \u2013 Build Artifact', function () {
    let xarPath;
    let xarContents;

    before(function () {
        xarPath = findXar();
        if (!xarPath) {
            // No XAR found \u2013 tests only make sense after `ant dist`
            this.skip();
        }
        xarContents = listXarContents(xarPath);
    });

    // -- XAR file itself ----------------------------------------------------
    describe('XAR artifact', function () {
        it('should exist in the dist/ directory', function () {
            assert.ok(xarPath, 'No XAR artifact found in dist/');
        });

        it(`should follow the naming pattern ${APP_NAME}-<version>-<hash>.xar`, function () {
            const filename = xarPath.split('/').pop();
            const escapedName = APP_NAME.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            assert.match(
                filename,
                new RegExp(`^${escapedName}-\\d+\\.\\d+\\.\\d+-[0-9a-f]+\\.xar$`),
                `Filename "${filename}" does not match expected pattern`
            );
        });

        it(`should embed the project version ${APP_VERSION} in its filename`, function () {
            const filename = xarPath.split('/').pop();
            assert.ok(
                filename.includes(APP_VERSION),
                `Expected version ${APP_VERSION} in filename "${filename}"`
            );
        });
    });

    // -- Required files inside the XAR -------------------------------------
    describe('XAR content \u2013 required files', function () {
        const REQUIRED_FILES = [
            'expath-pkg.xml',
            'repo.xml',
            'controller.xql',
            'index.html',
            'modules/app.xql',
            'modules/config.xqm',
            'modules/view.xql',
            'templates/page.html',
            'templates/landingPage.html',
        ];

        for (const file of REQUIRED_FILES) {
            it(`should contain ${file}`, function () {
                assert.ok(
                    xarContents.includes(file),
                    `"${file}" was not found inside the XAR package`
                );
            });
        }
    });

    // -- expath-pkg.xml metadata -------------------------------------------
    describe('expath-pkg.xml', function () {
        let xml;

        before(function () {
            xml = readXarFile(xarPath, 'expath-pkg.xml');
        });

        it(`should declare the correct package abbreviation (${APP_NAME})`, function () {
            assert.ok(
                xml.includes(`abbrev="${APP_NAME}"`),
                `Expected abbrev="${APP_NAME}" in expath-pkg.xml`
            );
        });

        it(`should contain the project version ${APP_VERSION}`, function () {
            assert.ok(
                xml.includes(`version="${APP_VERSION}-`),
                `Expected version="${APP_VERSION}-..." in expath-pkg.xml`
            );
        });

        it('should declare a minimum eXist-db dependency', function () {
            assert.ok(
                xml.includes('http://exist-db.org'),
                'Expected eXist-db dependency in expath-pkg.xml'
            );
        });

        it(`should reference the correct package URL (${APP_URL})`, function () {
            assert.ok(
                xml.includes(APP_URL),
                `Expected name="${APP_URL}" in expath-pkg.xml`
            );
        });
    });

    // -- repo.xml metadata -------------------------------------------------
    describe('repo.xml', function () {
        let xml;

        before(function () {
            xml = readXarFile(xarPath, 'repo.xml');
        });

        it(`should declare the correct install target (${APP_NAME})`, function () {
            assert.ok(
                xml.includes(`<target>${APP_NAME}</target>`),
                `Expected <target>${APP_NAME}</target> in repo.xml`
            );
        });

        it('should declare the CC BY 4.0 license', function () {
            assert.ok(
                xml.includes('<license>CC BY 4.0</license>'),
                'Expected <license>CC BY 4.0</license> in repo.xml'
            );
        });

        it('should be of type "application"', function () {
            assert.ok(
                xml.includes('<type>application</type>'),
                'Expected <type>application</type> in repo.xml'
            );
        });
    });
});
