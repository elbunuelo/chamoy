---
name: write-tutorial
description: Write step-by-step tutorials that teach understanding, not copy-paste. Use when the user says "write a tutorial", "create a guide", "teach me how to", or wants to document a learning path for a topic. Outputs to the project's tutorial/ directory.
---

# Write Tutorial

Write tutorials that teach readers to solve problems themselves rather than giving them answers to copy.

## Setup

Resolve the output directory:

```bash
DOCS_DIR="$HOME/Projects/claude/projects/$(basename "$PWD")"
mkdir -p "$DOCS_DIR/tutorial"
```

All tutorial files go in `$DOCS_DIR/tutorial/`.

## Before Writing

1. **Clarify the topic** — ask the user what the tutorial should cover if not obvious
2. **Identify the audience** — what should the reader already know?
3. **Define the outcome** — what can the reader do after completing the tutorial?

## Tutorial Structure

Use this structure for every tutorial:

```markdown
# Title

> One sentence: what the reader will be able to do after completing this.

## Prerequisites

- What the reader must already know or have installed
- Link to resources for prerequisites they might lack

## Step N: [Verb] [Thing]

**Why:** Explain the reasoning before the action. Why does this step exist?
What problem does it solve? What would happen without it?

**How:** Describe what to do and show the key code. Include short, focused snippets
(signatures, core logic, config, dependencies) — but not full files or boilerplate. The reader
fills in the surrounding structure themselves.

**Verify:** *(practical steps only)* A command the reader runs or program behavior
they observe to confirm the step worked. Include the exact command and expected
output/behavior. If a step is conceptual (explaining a mental model, describing
architecture, choosing between approaches), omit this section entirely.

> **Go deeper:** [Optional] Mention related topics worth exploring and what
> benefit they'd bring. e.g., "Research X to understand Y, which helps with Z."
```

### Step Types

- **Conceptual** — explains *why* something works, describes architecture, compares
  approaches. No code to run → no Verify section. These set up understanding for the
  practical steps that follow.
- **Practical** — the reader writes code, changes config, or runs a command. These
  MUST have a Verify section with a runnable command or observable program behavior.
  "You should see..." is not enough — tell them exactly what to run and what output
  to expect.

### Step Ordering

Steps must follow a logical, incremental arc. Before writing, outline the steps and
check that each one only uses concepts and code introduced in prior steps.

**The pattern:** concept → apply → verify → extend. Repeat.

1. **Start with the simplest working version** — get something running in the fewest
   steps possible (even if trivial). Early momentum matters.
2. **Introduce one idea per step** — if a step requires explaining two new concepts,
   split it. The reader should never wonder "wait, where did that come from?"
3. **Each practical step extends the previous result** — step 3's code builds on
   step 2's working state, not on a separate example. The reader is building one
   thing throughout.
4. **Never forward-reference** — don't say "we'll explain this later" or use code
   the reader hasn't seen yet. If something needs context, that context comes first
   as a conceptual step.
5. **Group related steps** — use section headers (`## Phase: ...`) to cluster steps
   into logical phases when the tutorial has 6+ steps.

**Self-check:** Read just the step titles in order. They should tell a coherent
story on their own: "Set up → Create → Connect → Test → Extend."

## Writing Rules

### DO

- **Explain WHY before HOW** — every step starts with motivation
- **Keep it concise** — telegraph; drop filler
- **Make practical steps verifiable** — reader runs a command and sees expected output before moving on
- **Keep the program runnable** — after each practical step, the reader should be able to run *something*; don't leave broken intermediate states across multiple steps
- **Show key code** — short snippets of signatures, core logic, and config; not full files
- **Cite exact names** — function names, CLI flags, config fields the reader needs
- **Suggest deeper research** — when a topic has depth, say so and explain the benefit

### DO NOT

- **No full file listings** — show the interesting parts, not boilerplate/glue
- **No hand-holding** — trust the reader to wire things together
- **No filler** — cut "In this step, we will..." and "Now let's..."
- **No assumptions about editor/OS** unless stated in prerequisites

### Fragment Examples

Good — shows core logic, reader builds the rest:

```markdown
Create a `validateInput` middleware factory:

\```js
function validateInput(schema) {
  return (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) return res.status(400).json(result.error.format());
    req.validated = result.data;
    next();
  };
}
\```

Export it and wire it into your router before the handler.
```

Bad — dumps an entire file with imports, boilerplate, and wiring:

```markdown
Create `src/middleware/validate.js`:
\```js
import { ZodError } from "zod";
import { userSchema } from "../schemas/user.js";
// ... 40 lines including router setup, error handler, exports
\```
```

## File Naming

Use kebab-case: `$DOCS_DIR/tutorial/<topic-name>.md`

If the tutorial is large (>300 lines), split into parts:
- `<topic-name>-01-setup.md`
- `<topic-name>-02-core.md`
- `<topic-name>-03-advanced.md`

Create an index file `<topic-name>-00-index.md` linking the parts.

## After Writing

- Read the tutorial back and cut anything that doesn't teach
- Verify each practical step's "Verify" section has a runnable command + expected output
- Confirm conceptual steps have no Verify section (don't force verification on theory)
- Confirm the tutorial can be followed top-to-bottom without skipping steps
- Read just the step titles in order — they should tell a coherent story
- Check no step uses concepts or code not yet introduced
