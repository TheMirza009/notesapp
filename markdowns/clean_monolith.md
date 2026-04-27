# CLAUDE_FLUTTER_UI.md

Companion to `CLAUDE.md`. Applies specifically to Flutter UI refactoring tasks.
These rules **extend** the base guidelines — they do not replace them.
When a conflict arises, the more restrictive rule wins.

---

## Flutter UI Refactor: Monolith Structure Rules

The goal is a **clean, readable monolith** with extracted business logic
but fully inline UI components. Every rule below exists to prevent the
most common LLM mistake in Flutter refactors: over-extraction.

---

## Rule 1 — Widget Extraction Threshold

**Default: keep everything inline. Extract only when forced.**

A widget may only be extracted into a separate class or method if **both**
of the following are true:

- The **exact same widget subtree** — same structure, same props, same
  styling — appears **3 or more times** within the file, AND
- That extracted widget is (or will be) **used in at least one other
  file** in the codebase.

If only one condition is met, keep it inline.

### What "exact same" means

Identical means structurally identical. Two `Container` widgets with
different colors or different children are **not** the same widget.
Do not extract to "reduce nesting" or "improve readability" — those
are style opinions, not duplication.

### Failing examples (do NOT extract these)

```dart
// ❌ Appears twice — below threshold. Keep inline.
Padding(
  padding: const EdgeInsets.all(16),
  child: Text('Section Title', style: titleStyle),
)

// ❌ Appears 3 times but only in this one file — keep inline.
// Extraction adds a class that lives nowhere else.
_buildSectionDivider() // do not create this
```

### Passing example (extraction allowed)

```dart
// ✅ Appears 4 times across 3 files → extract to _CountBadge widget
Container(
  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
  decoration: BoxDecoration(color: kGold, borderRadius: BorderRadius.circular(8)),
  child: Text('$count', style: badgeStyle),
)
```

---

## Rule 2 — What to Extract (Whitelist)

Only these two categories may leave the widget tree:

### 2a. Event handlers

Any `onTap`, `onPressed`, `onChanged`, `onSubmitted`, or gesture callback
that contains **more than one statement** must be extracted as a named
method on the `State` or widget class.

```dart
// ✅ Correct — handler extracted, widget stays inline
void _onSubmit() {
  if (!_formKey.currentState!.validate()) return;
  widget.onSetupComplete(_urlController.text.trim());
}

// In the tree:
ElevatedButton(
  onPressed: _onSubmit,
  child: const Text('Launch'),
)

// ❌ Wrong — single-statement handlers must stay inline
void _onClose() => Navigator.pop(context); // do not extract this
```

### 2b. Reused constants and styles

Any literal value (color, padding, `TextStyle`, `BoxDecoration`) that
appears **more than once** in the file must be extracted as a `const`
at the top of the file or inside the class.

```dart
// ✅ Correct — appears 4 times, extract as const
const _inputFill = Color(0xFF1E3F80);
const _labelStyle = TextStyle(color: Colors.white70, fontSize: 13);

// ❌ Wrong — appears once, leave it inline
const TextStyle(color: Colors.white70, fontSize: 13) // keep inline
```

---

## Rule 3 — Widget Tree Structure Requirements

### 3a. One uninterrupted tree

The `build` method must return a **single, uninterrupted widget tree**
from top to bottom. No helper methods (`_buildHeader()`, `_buildBody()`,
`_buildFooter()`). No splitting the tree across multiple methods and
reassembling with variables.

```dart
// ❌ Wrong — tree is split
Widget build(BuildContext context) {
  final header = _buildHeader();      // do not do this
  final body   = _buildBody();        // do not do this
  return Column(children: [header, body]);
}

// ✅ Correct — one continuous tree
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(children: [
      // HEADER
      Text('Title', style: _titleStyle),
      // BODY
      ListView.builder(...),
    ]),
  );
}
```

### 3b. Comment section markers

Divide the tree into logical sections using `//` comments at the
indentation level of the widgets they introduce. Use ALL CAPS.
Standard markers (adapt as needed):

```dart
// HEADER
// NAVIGATION / TABS
// SEARCH
// LIST / ITEMS
// ORDER ITEMS
// TOTALS
// PAYMENTS
// FOOTER
// LOADER
// ERROR STATE
// EMPTY STATE
// ACTION BUTTONS
// STATUS BANNER
```

There is no minimum or maximum number of markers. Use one wherever a
new logical section begins. Do not use markers for single-widget sections
that need no explanation.

### 3c. Const correctness

Apply `const` to every widget, constructor, and value that qualifies.
This is the **only** form of "optimization" that should be added during
a refactor unless explicitly asked for something else.

```dart
// ✅
const SizedBox(height: 24),
const Text('Hello', style: TextStyle(color: Colors.white)),

// ❌ — missing const where it is valid
SizedBox(height: 24),
Text('Hello', style: TextStyle(color: Colors.white)),
```

---

## Rule 4 — Optimization Targets (In Priority Order)

When refactoring, optimize in this order. Stop when the goal is met.
Do not optimize further than asked.

1. **Remove redundant wrappers.** A `Container` with no decoration, no
   constraints, and no margin/padding is a `SizedBox` or nothing.
   A `Padding` wrapping a widget that already has its own padding
   parameter is redundant. Delete these.

2. **Remove unnecessary nesting.** A `Column` with one child is not a
   `Column`. A `Center` wrapping a widget that is already centered by
   its parent is noise. Remove it.

3. **Reduce line count.** After removing redundant wrappers and
   unnecessary nesting, the line count should naturally drop. Do not
   artificially compress code onto fewer lines for its own sake —
   readability is the constraint.

4. **Const correctness.** See Rule 3c above.

5. **No speculative optimization.** Do not add `RepaintBoundary`,
   `AutomaticKeepAlive`, `ValueListenableBuilder`, or any other
   performance widget unless the task explicitly asks for it.

---

## Rule 5 — Absolute Prohibitions

These are never acceptable in a monolith refactor, regardless of
perceived benefit:

| Prohibited pattern | Why |
|---|---|
| `_buildX()` methods for one-time widgets | Splits the tree for no gain |
| `Widget get _header => ...` computed properties | Same as above |
| Extracting a widget used only once | Creates a class with no reuse value |
| Adding new abstractions not in the original | Violates CLAUDE.md §2 (Simplicity First) |
| Changing business logic during a UI refactor | Violates CLAUDE.md §3 (Surgical Changes) |
| Renaming existing methods or variables | Violates CLAUDE.md §3 |
| Adding error handling that wasn't there | Violates CLAUDE.md §2 |
| Changing state management patterns | Out of scope for a UI refactor |
| Reordering widget tree sections | Changes visual output; not permitted |

---

## Relationship to CLAUDE.md Base Rules

| CLAUDE.md rule | How it applies here |
|---|---|
| §1 Think Before Coding | Before extracting anything, verify it meets the 3-occurrence + multi-file threshold. State the count explicitly if uncertain. |
| §2 Simplicity First | The monolith **is** the simplest structure. Resist the instinct to break it up. Inline is simpler than extracted. |
| §3 Surgical Changes | Only touch code that directly serves the refactor goal. Do not clean up adjacent logic, fix unrelated bugs, or reformat unrelated sections. |
| §4 Goal-Driven Execution | Success criteria for a monolith refactor: (a) `build()` contains one uninterrupted tree, (b) no `_buildX()` methods exist, (c) identical UI output, (d) line count is equal or lower. |

---

## Verification Checklist

Before returning refactored code, confirm each item:

- [ ] `build()` returns a single uninterrupted widget tree
- [ ] No `_buildX()` helper methods were created
- [ ] No widget was extracted unless it appears 3+ times AND in multiple files
- [ ] All extracted widgets are used at their extraction site (no dead code)
- [ ] All multi-occurrence literals are extracted as `const`
- [ ] All event handlers with 2+ statements are extracted as named methods
- [ ] Single-statement handlers remain inline as lambdas
- [ ] `const` is applied wherever valid
- [ ] Redundant wrappers and unnecessary nesting have been removed
- [ ] Section comment markers are present and in ALL CAPS
- [ ] UI output is visually identical to the original
- [ ] No business logic was changed
- [ ] No adjacent unrelated code was touched
- [ ] Line count is equal to or lower than the original