# Class Refactor Workflow

A step-by-step prompt structure for refactoring a class cleanly.
Apply KISS, DRY, and SOLID. Readability is the top priority.
Plan before touching code. Ask before assuming.

---

## Step 1 — Read & Analyse

Read the full file. Do not touch anything yet.
Identify and list issues under these four categories:

**DRY violations**
- Duplicated logic across methods (same pattern copy-pasted)
- Repeated log lines or guard clauses

**KISS violations**
- Methods doing more than one thing
- Complex control flow that a simpler structure could replace
- Magic numbers with no explanation

**SOLID violations**
- Single Responsibility: one method handling multiple concerns
- Open/Closed: logic that would need to change in multiple places for one config tweak

**Navigability**
- No section headers — a new reader has to scan the whole file to orient
- Related methods scattered rather than grouped

---

## Step 2 — Clarify Before Planning

Ask only what you genuinely cannot determine from the code.
Cap at 3 questions. Format them as numbered, direct questions.

Useful questions to consider:
- Is this asymmetric behaviour intentional or an oversight? (e.g. method A re-scans on miss, method B doesn't)
- Is this connection left open deliberately or should it be closed after the test?
- Does this timeout value reflect an intentional decision or just what worked at the time?

Do NOT ask about things you can determine by reading the code or related files.
If a question is about flow (e.g. "does X run before Y?"), read the callers first.

---

## Step 3 — Plan

Present the plan as a table or numbered list before writing any code.

**For extracted helpers**, use a table:

| New method | Responsibility | Used by |
|---|---|---|
| `_resolveX(...)` | what it does | which methods call it |

**For a Control Panel**, list every tuneable value:

| Constant name | Value | Where it was |
|---|---|---|
| `_someTimeout` | `5s` | `_methodName` |

**State explicitly:**
- What does NOT change (public API, unrelated logic)
- Whether any external class is affected

Get confirmation before proceeding.

---

## Step 4 — Control Panel

Every class that has tuneable configuration must have a Control Panel section.
Place it at the top of the class body, before fields.

Rules:
- All magic numbers, durations, sizes, ports, and retry counts go here as `static const`
- Group related constants under a sub-comment (e.g. `// USB — chunked dispatch`)
- Add a one-line comment on any non-obvious value explaining WHY it exists
- No constant that is used in only one place and is self-explanatory needs to be here — use judgment

Example:
```dart
// ── Control Panel ───────────────────────────────────────────────────────────
// All tuneable values live here. No need to dig into method bodies to adjust.

// USB — permission handshake
static const _usbPermissionPolls        = 24;                       // max iterations
static const _usbPermissionPollInterval = Duration(milliseconds: 500);
static const _usbPostConnectDelay       = Duration(milliseconds: 300);

// USB — chunked dispatch (prevents 64 KB buffer overflow on cheap printers)
static const _usbChunkSize              = 8192;                     // bytes per packet
static const _usbChunkDelay             = Duration(milliseconds: 40);

// Network
static const _networkDefaultPort        = 9100;
static const _networkPrintTimeout       = Duration(seconds: 5);
```

---

## Step 5 — Section Headers

Divide the class into named sections using comment banners.
A new reader should be able to orient in under 10 seconds.

Standard sections (use what applies, skip what doesn't):
```
// ── Control Panel ─────────────────────────────────────────────────────────
// ── Fields ────────────────────────────────────────────────────────────────
// ── Discovery ─────────────────────────────────────────────────────────────
// ── Connection test ───────────────────────────────────────────────────────
// ── <Transport/Domain> helpers ────────────────────────────────────────────
// ── Dispatch ──────────────────────────────────────────────────────────────
// ── <Transport> implementations ───────────────────────────────────────────
// ── Cash drawer / Side operations ─────────────────────────────────────────
```

Rules:
- Section names reflect what the methods DO, not what they are (prefer "Discovery" over "Public methods")
- Private helpers that serve one section sit inside that section, not at the bottom
- Keep related methods together — don't split a public method from its private helpers

---

## Step 6 — Naming

Every identifier must be self-evident. A reader should never have to guess what a variable holds. No abbreviations — spell out the noun. But don't over-qualify either; the surrounding code provides context.

**Loop variables:**
```dart
for (final d in deviceList)  →  for (final device in deviceList)
for (final p in printers)    →  for (final printer in printers)
for (final k in _keywords)   →  for (final keyword in _keywords)
```

**Local variables:**
```dart
final mgr = FlutterThermalPrinter.instance;  →  final manager = FlutterThermalPrinter.instance;
final res = await scan(...);                 →  final result  = await scan(...);
final ok  = await connect(...);              →  ok is fine — its meaning is obvious from context
```

**The guiding question:** could a reader misread this name, even briefly?
If yes, rename. If the surrounding code makes the meaning obvious, a short name is fine.
Single-letter names are only acceptable for `i` (loop index) and `e` (caught error).

**Log statements — 1 line or expanded, never 2:**

If the message fits on one line, keep it on one line:
```dart
AppLog.info('Printer', 'USB print: SUCCESS for "${activePrinter!.name}"');
```

If it doesn't fit, use the expanded form: call opens on its own line, tag and message indented +2, closing `);` back at base indent. This makes the log visually distinct as a self-contained block:
```dart
AppLog.info(
  'Printer',
  'USB print: connected, sending ${bytes.length} bytes '
  '(${(bytes.length / 1024).toStringAsFixed(2)} KB)...',
);
```

The indentation is always relative to the call site — +2 for the arguments, base for the closing paren:
```dart
// Inside a method body (4-space base):
    AppLog.info(
      'Printer',
      'message...',
    );

// Inside a try/if block (6-space base):
      AppLog.info(
        'Printer',
        'message...',
      );
```

When the message itself is too long for one string, split at the natural boundary between static description and dynamic values:
```dart
AppLog.info(
  'Printer',
  'USB print: sending ${bytes.length} bytes '   // ← static label + dynamic count
  '(${(bytes.length / 1024).toStringAsFixed(2)} KB)...',  // ← unit/format detail
);
```

Never split mid-phrase just to hit a line limit.

**Private method comments — `//` for utility, `///` for important helpers:**

Not all private methods are equal. Use the comment style to signal importance:

- `///` doc comment — for private methods that have meaningful contracts, non-obvious behaviour, or are the kind of thing a maintainer would want IDE hover-docs on (e.g. a helper that encapsulates a non-trivial algorithm or protocol step).
- `//` single-line comment — for private methods that are clearly named and exist purely to reduce duplication or keep a wrapper readable. One line only; if you need more than one line the method name is probably wrong.

```dart
/// Returns the cached native printer object for [device].
/// On a cache miss, clears the cache and re-runs discovery before retrying.
Future<ftp.Printer?> _resolveUsbTarget(PrinterDevice device) async { ... }

// Resolves the USB target, connects, and dispatches bytes in chunks.
Future<bool> _printUsb(List<int> bytes) async { ... }
```

Public methods always use `///`.

---

## Step 7 — Extract Helpers

When a method does more than one thing, extract each concern into a focused private method.
The original method becomes a wrapper that reads like a sequence of steps.

Rules:
- Each extracted method does exactly one thing and has a name that says what
- The wrapper method should read top-to-bottom like plain English
- If two methods share a pattern (resolve → connect → send), extract the shared parts so both use the same helper
- Do not extract a single-use, 3-line block just because it could be a method — only extract when it reduces duplication or meaningfully improves readability

Target shape of a wrapper after extraction:
```dart
Future<bool> _printUsb(List<int> bytes) async {
  final target = await _resolveUsbTarget(activePrinter!);
  if (target == null) return false;
  await _connectUsb(target);
  await _dispatchChunked(target, bytes);
  return true;
}
```

---

## Step 7 — Simplicity Check

Before finalising, ask for each method or pattern:
- Could a guard clause replace a nested condition?
- Could a ternary replace a two-branch if/else?
- Is there a Completer, StreamController, or Completer-based pattern that a simpler await or conditional achieves?
- Are there log lines duplicated across methods that a single extracted log helper or consolidation would fix?

Do not introduce abstractions to answer "yes" to these — only simplify if the result is obviously clearer.

---

## Step 8 — Inline Section Comments

Not every long method needs to be split into smaller helpers. Before extracting, ask:
- Is this method already a wrapper — calling helpers and routing through phases?
- Would extraction just rename a block without simplifying the logic?

If yes, **add inline `// —` section comments** instead. One comment per phase, placed directly above its block. A reader should be able to scan the comment lines alone and understand the full execution path.

```dart
Future<bool> printReceipt(ReceiptData receipt) async {
  // — guard: reject or deduplicate concurrent print requests
  if (_isPrinting) { ... }
  _isPrinting = true;

  try {
    // — setup: capture receipt state and resolve renderer
    _lastReceipt = receipt;
    ...

    // — route: no printer → preview fallback
    if (_activePrinter == null) { ... }

    // — route: multi-page WebView path
    if (useWebView && ...) { ... }

    // — single page: build bytes and dispatch
    final bytes = await _buildBytes(receipt, useWebView);
    ...
  }
}
```

**When to extract instead:**
If a loop body exceeds ~15 lines, extract it into a named helper. The loop then reads as: iterate → call helper → inter-iteration logic (delays, counters). The helper itself can use inline `// —` comments for its own phases (e.g. `// — render`, `// — dispatch`).

```dart
// _printMultiPage loop after extraction:
for (int i = 0; i < chunks.length; i++) {
  final pageNumber = i + 1;
  final ok         = await _printOnePage(receipt, chunks[i], pageNumber, totalPages);
  if (!ok) allOk = false;

  if (i < chunks.length - 1) {
    await Future.delayed(...);
  }
}
```

---

## Step 9 — Verify No Breakage

Before submitting:
- Confirm the public API (method names, signatures, return types) is identical
- Grep for usages of any method you renamed or moved
- Check if any other class imports or calls internal methods (should be none, but verify)
- Confirm that extracted constants have the same effective values as the magic numbers they replaced

---

## Principles Summary

| Principle | Applied as |
|---|---|
| **KISS** | Simpler control flow, no over-engineering, guard clauses over nesting |
| **DRY** | Shared helpers for duplicated patterns, single source for config values |
| **SOLID / SRP** | Each method has one job; wrapper orchestrates, helpers execute |
| **Readability first** | Section headers, control panel, descriptive method names, wrapper methods that read like steps |
| **Surgical changes** | Don't touch what isn't broken; every changed line traces to the task |
