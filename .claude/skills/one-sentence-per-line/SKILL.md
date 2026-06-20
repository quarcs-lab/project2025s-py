---
name: one-sentence-per-line
description: >
  This skill should be used when the user asks to "reformat", "fix line breaks",
  "one sentence per line", "split sentences", "fix formatting", or "enforce sentence breaks".
  Also use when the user mentions multi-sentence lines, sentence-per-line formatting,
  or asks to clean up paragraph formatting in the manuscript. Reformats index.qmd so that
  each sentence starts on its own line, improving git diffs and collaborative editing.
---

# One Sentence Per Line Reformatting

## Role

Act as a formatting assistant that enforces the manuscript convention: **one sentence per line** in `index.qmd`. This convention improves git diffs and collaborative editing.

## Target file

The manuscript is `index.qmd` in the project root. Read the entire file before making any edits.

## Detection rules

### What to flag

Flag any line that contains a sentence-ending punctuation mark (`.`, `?`, `!`) followed by a space and then an uppercase letter or `@`-citation, indicating two or more sentences on the same line.

Pattern: sentence-ending punctuation + space + new sentence start, e.g.:
- `... end of sentence. Start of next sentence ...`
- `... end of sentence. @author2020 found that ...`
- `... a question? The answer is ...`
- `... important! However, ...`

### What to exclude (do not flag)

**Common abbreviations** — these contain periods but are not sentence boundaries:
- `e.g.`, `i.e.`, `et al.`, `vs.`, `Eq.`, `Fig.`, `Tab.`, `No.`
- `Dr.`, `St.`, `Jr.`, `Sr.`, `Mr.`, `Mrs.`, `Ms.`, `Prof.`
- `U.S.`, `U.K.`, `E.U.`

**Inline math** — periods inside `$...$` expressions (e.g., `$I = 0.73$`) are not sentence endings.

**Parenthetical citations** — patterns like `[@author_year]` or `[see @key1; @key2]`.

**The `abstract: |` YAML block** — already formatted correctly using YAML multiline syntax.

### Protected zones (skip entirely)

Do not scan or modify lines inside these zones:

| Zone | Start marker | End marker |
|------|-------------|------------|
| YAML frontmatter | `---` (line 1) | next `---` |
| Code blocks | `` ``` `` | `` ``` `` |
| Math blocks | `$$` | `$$` |
| Figure/table captions | line starts with `![` | end of line |
| Shortcodes | line contains `{{<` and `>}}` | end of line |
| HTML comments | `<!--` | `-->` |
| Footnote definitions | `[^n]:` continuation lines (indented) | next unindented line |

## Execution steps

1. **Read** the full manuscript (`index.qmd`)
2. **Scan** every line outside protected zones for multi-sentence lines using the detection rules above
3. **Report** findings in a structured table:

   | # | Line | Current text (truncated to ~80 chars) | Proposed split |
   |---|------|---------------------------------------|----------------|
   | 1 | 42 | `...first sentence. Second sentence starts...` | Split after `.` |
   | 2 | 67 | `...question? The answer is...` | Split after `?` |
   | ... | ... | ... | ... |

   Below the table, show the total count of lines that need splitting.

4. **Wait for user approval** before applying any edits. Do NOT apply edits automatically.
5. **Apply** edits using the Edit tool, working top-to-bottom through the file. For each flagged line, replace the multi-sentence line with the split version (each sentence on its own line, preserving leading indentation).
6. **Verify** by re-scanning the full file to confirm zero remaining violations. Report the result.

## Splitting rules

When splitting a multi-sentence line:

- Place each sentence on its own line
- Preserve the leading indentation of the original line for all resulting lines
- Do not add or remove blank lines between sentences (sentences within the same paragraph remain on consecutive lines with no blank line between them)
- Do not alter the text content itself — only change where line breaks occur
- If a line contains three or more sentences, split at each sentence boundary

## Important notes

- This skill only reformats line breaks — it does not change wording, fix grammar, or alter content
- Blank lines between paragraphs must be preserved exactly as they are
- When in doubt about whether a period is a sentence boundary, err on the side of NOT splitting (false negatives are safer than false positives)
- The `abstract: |` block in YAML frontmatter uses YAML multiline syntax and should not be modified
