#!/usr/bin/env node
/**
 * validate.js - Comprehensive validation for the Jacque-Copy Swift project.
 *
 * Validates:
 *  1. Project structure completeness
 *  2. All Swift files for balanced braces/brackets
 *  3. Import consistency
 *  4. Type references across files
 *  5. Documentation presence in all public APIs
 *  6. Configuration file correctness
 *  7. File naming conventions
 *  8. No TODO/placeholder/fixme in production code
 *
 * Usage: node Scripts/validate.js
 */

const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..");
const SOURCES = path.join(ROOT, "Sources", "JacqueCopy");
const TESTS = path.join(ROOT, "Tests");
const DOCS = path.join(ROOT, "Documentation");

let errors = 0;
let warnings = 0;
let checks = 0;

function logCheck(name) {
  checks++;
  console.log(`\n${"─".repeat(60)}`);
  console.log(`  CHECK ${checks}: ${name}`);
  console.log(`${"─".repeat(60)}`);
}

function error(msg) {
  errors++;
  console.log(`  ❌ ERROR: ${msg}`);
}

function warn(msg) {
  warnings++;
  console.log(`  ⚠️  WARNING: ${msg}`);
}

function ok(msg) {
  console.log(`  ✅ ${msg}`);
}

function getAllSwiftFiles(dir) {
  const results = [];
  function walk(d) {
    const entries = fs.readdirSync(d, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(d, entry.name);
      if (entry.isDirectory()) {
        walk(fullPath);
      } else if (entry.name.endsWith(".swift")) {
        results.push(fullPath);
      }
    }
  }
  walk(dir);
  return results;
}

// ============================================================
// CHECK 1: Project Structure
// ============================================================
logCheck("Project Structure Completeness");

const requiredDirs = [
  "Sources/JacqueCopy/App",
  "Sources/JacqueCopy/Clipboard",
  "Sources/JacqueCopy/Hotkeys",
  "Sources/JacqueCopy/Models",
  "Sources/JacqueCopy/Services",
  "Sources/JacqueCopy/Views/MenuBar",
  "Sources/JacqueCopy/Views/Settings",
  "Sources/JacqueCopy/Views/History",
  "Sources/JacqueCopy/Views/Components",
  "Sources/JacqueCopy/Utilities",
  "Sources/JacqueCopy/Extensions",
  "Sources/JacqueCopy/Resources",
  "Tests/Unit",
  "Documentation",
  ".github/workflows",
  ".github/ISSUE_TEMPLATE",
  "Resources/Assets.xcassets/AppIcon.appiconset",
  "Scripts",
];

for (const dir of requiredDirs) {
  const fullPath = path.join(ROOT, dir);
  if (fs.existsSync(fullPath)) {
    ok(`Directory exists: ${dir}`);
  } else {
    error(`Missing directory: ${dir}`);
  }
}

// Check for required root files
const requiredRootFiles = [
  "Package.swift",
  "LICENSE",
  ".gitignore",
];
for (const file of requiredRootFiles) {
  if (fs.existsSync(path.join(ROOT, file))) {
    ok(`Root file exists: ${file}`);
  } else {
    error(`Missing root file: ${file}`);
  }
}

// ============================================================
// CHECK 2: All Required Source Files
// ============================================================
logCheck("Required Source Files");

const requiredSourceFiles = [
  "App/JacqueCopyApp.swift",
  "Clipboard/ClipboardEngine.swift",
  "Clipboard/PasteboardManager.swift",
  "Clipboard/HistoryStore.swift",
  "Hotkeys/HotkeyManager.swift",
  "Hotkeys/ShortcutManager.swift",
  "Models/ClipboardItem.swift",
  "Services/AppSettings.swift",
  "Services/LaunchService.swift",
  "Services/NotificationService.swift",
  "Services/UpdateChecker.swift",
  "Services/DiagnosticsService.swift",
  "Views/MenuBar/MenuBarContentView.swift",
  "Views/Settings/SettingsView.swift",
  "Views/History/HistoryBrowserView.swift",
  "Views/Components/SearchBar.swift",
  "Views/Components/ClipboardItemRow.swift",
  "Utilities/Logger.swift",
  "Utilities/ClipboardItemCoder.swift",
  "Utilities/AppInfo.swift",
  "Extensions/FoundationExtensions.swift",
  "Resources/Info.plist",
  "Resources/JacqueCopy.entitlements",
];

for (const file of requiredSourceFiles) {
  const fullPath = path.join(SOURCES, file);
  if (fs.existsSync(fullPath)) {
    ok(`Source: ${file}`);
  } else {
    error(`Missing source: ${file}`);
  }
}

// ============================================================
// CHECK 3: Swift File Syntax - Balanced Braces & Brackets
// ============================================================
logCheck("Swift Syntax - Balanced Braces/Brackets");

const swiftFiles = getAllSwiftFiles(SOURCES).concat(getAllSwiftFiles(TESTS));
console.log(`  Found ${swiftFiles.length} Swift files to check\n`);

for (const file of swiftFiles) {
  const content = fs.readFileSync(file, "utf8");
  const lines = content.split("\n");
  const relPath = path.relative(ROOT, file);

  // Count braces
  let openBraces = 0;
  let closeBraces = 0;
  let openParens = 0;
  let closeParens = 0;
  let openBrackets = 0;
  let closeBrackets = 0;

  // Track string literals to not count braces inside strings
  let inString = false;
  let inComment = false;
  let stringChar = "";

  for (let i = 0; i < content.length; i++) {
    const ch = content[i];
    const next = content[i + 1] || "";

    // Handle comments
    if (!inString && ch === "/" && next === "/") {
      // Line comment - skip to end of line
      while (i < content.length && content[i] !== "\n") i++;
      continue;
    }
    if (!inString && ch === "/" && next === "*") {
      inComment = true;
      i++;
      continue;
    }
    if (inComment && ch === "*" && next === "/") {
      inComment = false;
      i++;
      continue;
    }
    if (inComment) continue;

    // Handle strings
    if (ch === '"' && !inString) {
      inString = true;
      stringChar = '"';
      continue;
    }
    if (ch === '"' && inString && stringChar === '"') {
      inString = false;
      continue;
    }
    if (inString) continue;

    // Count braces
    if (ch === "{") openBraces++;
    if (ch === "}") closeBraces++;
    if (ch === "(") openParens++;
    if (ch === ")") closeParens++;
    if (ch === "[") openBrackets++;
    if (ch === "]") closeBrackets++;
  }

  let fileOk = true;
  if (openBraces !== closeBraces) {
    error(`${relPath}: Unbalanced braces (${openBraces} open, ${closeBraces} close)`);
    fileOk = false;
  }
  if (openParens !== closeParens) {
    error(`${relPath}: Unbalanced parentheses (${openParens} open, ${closeParens} close)`);
    fileOk = false;
  }
  if (openBrackets !== closeBrackets) {
    error(`${relPath}: Unbalanced brackets (${openBrackets} open, ${closeBrackets} close)`);
    fileOk = false;
  }

  if (fileOk) {
    // Only log verbose for files with issues
  }
}

// Check each file individually for issues and report clean ones
for (const file of swiftFiles) {
  const content = fs.readFileSync(file, "utf8");
  const relPath = path.relative(ROOT, file);
  const lines = content.split("\n");

  // Check for force unwrapping (dangerous pattern)
  const forceUnwrapCount = (content.match(/\w+!/g) || []).length;
  if (forceUnwrapCount > 3) {
    warn(`${relPath}: ${forceUnwrapCount} force unwraps found`);
  }

  // Check for huge files (>500 lines)
  if (lines.length > 500) {
    warn(`${relPath}: Large file (${lines.length} lines) — consider splitting`);
  }
}

ok(`Checked ${swiftFiles.length} Swift files for balanced delimiters`);

// ============================================================
// CHECK 4: No TODO/Placeholder/FIXME in Source Code
// ============================================================
logCheck("No TODO / Placeholder / FIXME");

let todoCount = 0;
for (const file of swiftFiles) {
  const content = fs.readFileSync(file, "utf8");
  const relPath = path.relative(ROOT, file);

  // Match TODO, FIXME, HACK, placeholder but NOT in comments that explain why
  const todoMatches = content.match(/\/\/\s*(TODO|FIXME|HACK|PLACEHOLDER|TEMP|WORKAROUND):?/gi) || [];
  for (const match of todoMatches) {
    const lineNum = content.substring(0, content.indexOf(match)).split("\n").length;
    warn(`${relPath}:${lineNum}: ${match.trim()}`);
    todoCount++;
  }
}

if (todoCount === 0) {
  ok("No TODO/FIXME/placeholder comments found");
}

// ============================================================
// CHECK 5: Import Consistency
// ============================================================
logCheck("Import Statements");

const expectedImports = {
  "Foundation": 0,
  "AppKit": 0,
  "SwiftUI": 0,
  "CoreGraphics": 1,
  "ServiceManagement": 1,
  "UserNotifications": 2,
  "KeyboardShortcuts": 2,
  "Sparkle": 1,
};

for (const file of swiftFiles) {
  const content = fs.readFileSync(file, "utf8");
  const relPath = path.relative(ROOT, file);
  const imports = content.match(/^import\s+(\w+)/gm) || [];

  for (const imp of imports) {
    const module = imp.replace("import ", "").trim();
    if (expectedImports.hasOwnProperty(module)) {
      expectedImports[module]++;
    } else if (!["Combine", "AppKit"].includes(module)) {
      // Not in our expected list but valid
    }
  }
}

// Verify required imports exist in the project
const importUsage = {
  "UserNotifications": "NotificationService.swift",
  "ServiceManagement": "LaunchService.swift",
  "Sparkle": "UpdateChecker.swift",
  "KeyboardShortcuts": "HotkeyManager.swift, ShortcutManager.swift",
  "CoreGraphics": "HotkeyManager.swift (CGEvent)",
};

for (const [module, expectedFile] of Object.entries(importUsage)) {
  let found = false;
  for (const file of swiftFiles) {
    const content = fs.readFileSync(file, "utf8");
    if (content.includes(`import ${module}`)) {
      found = true;
      break;
    }
  }
  if (found) {
    ok(`Import ${module} found (used by ${expectedFile})`);
  } else {
    error(`Import ${module} not found in any file (expected in ${expectedFile})`);
  }
}

// ============================================================
// CHECK 6: Core Type Definitions and References
// ============================================================
logCheck("Core Type Cross-References");

// Collect all type definitions
const typeDefs = new Map();
for (const file of swiftFiles) {
  const content = fs.readFileSync(file, "utf8");
  const relPath = path.relative(ROOT, file);

  // Match class, struct, enum, protocol, extension definitions
  const defs = content.match(/(?:public\s+)?(?:final\s+)?(?:class|struct|enum|protocol|actor|extension)\s+(\w+)/g) || [];
  for (const def of defs) {
    const name = def.replace(/(public |final |class |struct |enum |protocol |actor |extension )/g, "").trim();
    if (!typeDefs.has(name)) {
      typeDefs.set(name, []);
    }
    typeDefs.get(name).push(relPath);
  }
}

const requiredTypes = [
  "ClipboardEngine",
  "PasteboardManager",
  "HistoryStore",
  "HotkeyManager",
  "ShortcutManager",
  "ClipboardItem",
  "ClipboardIdentifier",
  "AppSettings",
  "LaunchService",
  "NotificationService",
  "UpdateChecker",
  "DiagnosticsService",
  "MenuBarContentView",
  "SettingsView",
  "HistoryBrowserView",
  "SearchBar",
  "ClipboardItemRow",
  "MenuBarIconView",
  "AppDelegate",
  "JacqueCopyApp",
  "Logger",
  "AppInfo",
  "ClipboardItemCoder",
  "LogEntry",
  "LogLevel",
];

for (const type of requiredTypes) {
  if (typeDefs.has(type)) {
    ok(`Type ${type} defined in ${typeDefs.get(type).join(", ")}`);
  } else {
    error(`Type ${type} is not defined anywhere`);
  }
}

// ============================================================
// CHECK 7: Configuration File Validity
// ============================================================
logCheck("Configuration Files");

// Package.swift
const packageSwift = path.join(ROOT, "Package.swift");
if (fs.existsSync(packageSwift)) {
  const content = fs.readFileSync(packageSwift, "utf8");
  if (content.includes("name:") && content.includes("macOS(.v14)")) {
    ok("Package.swift: Valid Swift package manifest");
  } else {
    error("Package.swift: Missing required fields");
  }
}

// Info.plist
const infoPlist = path.join(SOURCES, "Resources", "Info.plist");
if (fs.existsSync(infoPlist)) {
  const content = fs.readFileSync(infoPlist, "utf8");
  const requiredKeys = [
    "CFBundleIdentifier",
    "CFBundleName",
    "LSUIElement",
    "LSMinimumSystemVersion",
  ];
  for (const key of requiredKeys) {
    if (content.includes(key)) {
      ok(`Info.plist: ${key} present`);
    } else {
      error(`Info.plist: Missing ${key}`);
    }
  }
}

// .gitignore
const gitignore = path.join(ROOT, ".gitignore");
if (fs.existsSync(gitignore)) {
  const content = fs.readFileSync(gitignore, "utf8");
  const requiredPatterns = [".DS_Store", ".build/", "DerivedData/", "*.dmg", "*.xcarchive"];
  for (const pattern of requiredPatterns) {
    if (content.includes(pattern)) {
      ok(`.gitignore: ${pattern} present`);
    } else {
      warn(`.gitignore: Missing ${pattern}`);
    }
  }
}

// ============================================================
// CHECK 8: Documentation Existence
// ============================================================
logCheck("Documentation Files");

const requiredDocs = [
  "README.md",
  "ARCHITECTURE.md",
  "BUILD.md",
  "INSTALL.md",
  "CHANGELOG.md",
  "ROADMAP.md",
  "CONTRIBUTING.md",
  "SECURITY.md",
  "FAQ.md",
  "CODE_OF_CONDUCT.md",
  "RELEASE_NOTES.md",
];

for (const doc of requiredDocs) {
  if (fs.existsSync(path.join(DOCS, doc))) {
    ok(`Documentation/${doc} exists`);
  } else {
    error(`Missing documentation: ${doc}`);
  }
}

// ============================================================
// CHECK 9: GitHub CI/CD
// ============================================================
logCheck("GitHub CI/CD Files");

const requiredCIFiles = [
  ".github/workflows/build.yml",
  ".github/workflows/release.yml",
  ".github/workflows/dependabot.yml",
  ".github/dependabot.yml",
  ".github/CODEOWNERS",
  ".github/pull_request_template.md",
  ".github/ISSUE_TEMPLATE/bug_report.yml",
  ".github/ISSUE_TEMPLATE/feature_request.yml",
];

for (const file of requiredCIFiles) {
  const fullPath = path.join(ROOT, file);
  if (fs.existsSync(fullPath)) {
    const content = fs.readFileSync(fullPath, "utf8");
    if (content.length > 50) {
      ok(`${file}: Present and populated`);
    } else {
      warn(`${file}: Present but may be too short`);
    }
  } else {
    error(`Missing CI/CD file: ${file}`);
  }
}

// ============================================================
// CHECK 10: Swift API Documentation Comments
// ============================================================
logCheck("Documentation Comments on Public APIs");

let documentedApis = 0;
let undocumentedApis = 0;

for (const file of swiftFiles) {
  const content = fs.readFileSync(file, "utf8");
  const relPath = path.relative(ROOT, file);

  // Find public declarations
  const publicDefs = content.match(/public\s+(?:final\s+)?(?:class|struct|enum|protocol|func|var|let|init)\s+\w+/g) || [];
  for (const def of publicDefs) {
    // Find the position of this definition
    const pos = content.indexOf(def);
    // Look backwards for a doc comment (///)
    const before = content.substring(Math.max(0, pos - 200), pos);
    if (before.includes("///")) {
      documentedApis++;
    } else {
      undocumentedApis++;
    }
  }
}

if (undocumentedApis > 0) {
  warn(`${undocumentedApis} public APIs lack documentation comments (${documentedApis} have them)`);
} else {
  ok(`All ${documentedApis} public APIs are documented`);
}

// ============================================================
// CHECK 11: Test File Validation
// ============================================================
logCheck("Test Files");

const testFiles = getAllSwiftFiles(TESTS);
if (testFiles.length >= 3) {
  ok(`Found ${testFiles.length} test files`);

  for (const file of testFiles) {
    const content = fs.readFileSync(file, "utf8");
    const relPath = path.relative(ROOT, file);

    if (content.includes("XCTest")) {
      ok(`${relPath}: Contains XCTest references`);
    } else {
      warn(`${relPath}: Missing XCTest import`);
    }

    // Count test methods
    const testMethods = content.match(/func\s+test\w+\(\)/g) || [];
    ok(`  → ${testMethods.length} test methods`);
  }
} else {
  error(`Only ${testFiles.length} test files found (expected at least 3)`);
}

// ============================================================
// SUMMARY
// ============================================================
console.log(`\n${"═".repeat(60)}`);
console.log(`  VALIDATION COMPLETE`);
console.log(`${"═".repeat(60)}`);
console.log(`  Checks run:    ${checks}`);
console.log(`  Errors:        ${errors}`);
console.log(`  Warnings:      ${warnings}`);
console.log(`  Swift files:   ${swiftFiles.length}`);
console.log(`  Test files:    ${testFiles.length}`);
console.log(`${"═".repeat(60)}`);

if (errors === 0 && warnings < 5) {
  console.log("\n  ✅ PROJECT PASSES VALIDATION\n");
  process.exit(0);
} else if (errors === 0) {
  console.log("\n  ⚠️  PROJECT PASSES WITH WARNINGS\n");
  process.exit(0);
} else {
  console.log(`\n  ❌ PROJECT HAS ${errors} ERRORS\n`);
  process.exit(1);
}
