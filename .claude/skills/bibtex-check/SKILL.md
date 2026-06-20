---
name: bibtex-check
description: >
  This skill should be used when the user asks to "check references",
  "check bibliography", "check bibtex", "audit references", "update references",
  "fix bibtex", "check citations", or "check bib". Also use when the user mentions
  missing volume, pages, or DOI in bibliography entries. Audits references.bib
  for completeness and currency, checking only entries cited in the manuscript.
---

# BibTeX Reference Audit

## Goal

Check that all references cited in `index.qmd` have complete and up-to-date
metadata in `references.bib`. Only audit entries that are actually cited in the
manuscript — ignore uncited entries in the bib file.

## Step 1: Extract cited keys from `index.qmd`

Read `index.qmd` and extract all citation keys. Citation patterns to match:

- `@citekey` — inline citation
- `[@citekey]` — parenthetical citation
- `[@key1; @key2]` — multi-citation
- `-@citekey` — suppress-author citation
- `@citekey [p. 10]` — citation with locator

Use Grep to find all `@`-prefixed citation keys in `index.qmd`:

```
pattern: @([a-zA-Z][a-zA-Z0-9_:-]+)
```

Exclude lines that are:
- YAML frontmatter (between `---` delimiters at the top of the file)
- Code blocks or embed shortcodes (`{{< embed ...`)
- Comments (`<!-- ... -->`)
- The `bibliography:` YAML field itself

Deduplicate and sort the keys to produce the **cited set**. Report the count
(expect ~49 cited keys).

## Step 2: Audit each cited entry in `references.bib`

Read `references.bib`. For each key in the cited set, locate its bib entry and
check completeness based on entry type.

### Required fields by type

| Entry type | Required fields |
|------------|----------------|
| `@article` | author, title, journal, year, volume, pages, doi |
| `@book` | author/editor, title, publisher, year |
| `@incollection` | author, title, booktitle, publisher, year |
| `@inproceedings` | author, title, booktitle, year |
| `@techreport` | author, title, institution, year |
| `@phdthesis` | author, title, school, year |
| `@misc` | author, title, year |

### Issues to flag

1. **Missing required fields** — any field from the table above that is absent or empty
2. **`@software` type** — not recognized by `region.bst` (the REGION journal style); suggest changing to `@misc`
3. **Books misclassified as `@article`** — entry has a `publisher` field but is typed as `@article`; suggest changing to `@book`
4. **Missing DOI** — flag as informational (DOI is strongly recommended for journal articles)
5. **Stale ahead-of-print** — article has DOI but missing volume/pages (may have been published since the entry was added)

### DOI-based metadata lookup

For entries that have a DOI but are missing volume, number, or pages:

1. Use WebFetch on `https://doi.org/<doi>` to fetch the DOI landing page
2. Extract current volume, issue/number, pages, and year from the page
3. If the article is still ahead-of-print (no volume/pages on the publisher page), note it as unresolvable

## Step 3: Report findings

Present a structured report with three sections:

### 3a. Summary

```
Cited keys: XX
Complete entries: XX
Entries with issues: XX
```

### 3b. Issues found

For each entry with issues, report in a table:

| # | Citekey | Type | Issue | Current value | Proposed fix |
|---|---------|------|-------|---------------|-------------|
| 1 | smith2020 | @article | missing volume | — | vol. 45 (from DOI) |
| 2 | jones2019 | @software | wrong type | @software | change to @misc |
| ... | ... | ... | ... | ... | ... |

### 3c. Unresolvable

List any entries where volume/pages cannot be determined (ahead-of-print articles)
and note that these should be rechecked when the article is formally published.

## Step 4: Wait for approval

**Do NOT apply any edits automatically.** Present the report and ask the user
which fixes to apply. Only after explicit approval, use the Edit tool to update
`references.bib`.

## Important notes

- Only check entries in the **cited set** extracted from `index.qmd`
- Do not modify uncited entries in `references.bib`
- Do not add or remove entries — only fix metadata within existing entries
- When fetching DOI pages, respect rate limits (pause between fetches if needed)
- If a DOI resolves to a paywall with no metadata visible, note it and move on
