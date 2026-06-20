---
name: prepare-region-submission
description: >
  Use this skill when the user asks to "prepare a REGION submission",
  "freeze a blind copy for the editor", "create a submission bundle",
  "send the paper to REGION", or "make a submission folder for peer review".
  Creates a self-contained, reviewer-blind submission folder at
  legacy/submission-YYYYMMDD/ containing the REGION PDF, Word version,
  single-file HTML, a fully standalone LaTeX tree, a blind manifest README,
  and a non-blind cover letter addressed to the editor. Verifies that the
  standalone LaTeX tree compiles end-to-end and that no author-identifying
  strings leak into reviewer-facing files before reporting success.
---

# Prepare REGION Submission Bundle

## Goal

Build a self-contained, date-stamped submission bundle at
`legacy/submission-YYYYMMDD/` that can be sent to the editor of REGION — The
Journal of ERSA. The bundle must satisfy three properties simultaneously:

1. **Self-contained.** A reviewer can open the bundle and rebuild every
   artifact (LaTeX PDF, HTML, DOCX) using only files inside it.
2. **Reviewer-blind.** Every file seen by reviewers (`manuscript-REGION.pdf`,
   `manuscript.docx`, `manuscript-standalone.html`, the entire
   `latex-manuscript/` subtree, and the top-level `README.md`) must have no
   identifying strings — no author names, no grant numbers, no author-owned
   URLs, no institutional affiliations.
3. **Editor-informative.** A non-blind `CoverLetter.md` at the top of the
   bundle carries the real author info, the corresponding-author contact,
   and the pitch for the paper. The editor distributes only the blind files
   to reviewers.

## Important

- **Do NOT commit or push.** Stop after verification and let the user handle
  `git add` / `git commit` / `git push` manually. This matches project
  convention — no existing skill performs git operations.
- **Wait for user approval** before writing any file inside the bundle. Each
  phase that produces output must show the user what will be written and ask
  for explicit confirmation.
- **Never modify `index.qmd`.** If anonymization is required, operate on a
  temporary `index-blind.qmd` at the project root and delete it after render.
- **Never modify `_quarto.yml`.** The standalone HTML is produced via
  command-line overrides; no yaml changes are needed.

## Phase 1: Preflight

Before any destructive action, confirm:

| Check | Command | Required result |
|---|---|---|
| Working tree clean | `git status --short` | No output (or only uncommitted submission work the user is actively reviewing) |
| Manuscript source present | `ls index.qmd _quarto.yml scripts/clean-render.sh references.bib` | All four files exist |
| REGION extension present | `ls _extensions/region-ersa/REGION/` | Contains `regart.cls`, `region.sty`, `REGION.bst`, `Titlepage_21.pdf`, `Titlepage_22.pdf`, `ERSA_logo.png`, `wutext.pdf`, `fwf.pdf`, `CC-BY-88x31.png` |
| Quarto on PATH | `quarto --version` | Prints version |
| lualatex on PATH | `which lualatex` | Prints a path |
| pdfinfo on PATH (optional) | `which pdfinfo` | Prints a path, else note the PDF metadata check in Phase 8 will use Python instead |

Compute today's date as `YYYYMMDD`:

```bash
date +%Y%m%d
```

Target directory is `legacy/submission-YYYYMMDD/`. If it already exists, stop
and ask the user:

1. Overwrite the existing folder (delete then recreate)
2. Create with a suffix like `legacy/submission-YYYYMMDD-b/`
3. Abort

Do not proceed until the user picks one.

If the working tree is dirty, report which files are modified and ask the
user to stash, commit, or proceed anyway. Default is to refuse and wait.

## Phase 2: Load author config

Read `.claude/author-config.yml`. Expected shape:

```yaml
corresponding_author:
  name: "Carlos Mendez"
  affiliation: "Graduate School of International Development, Nagoya University, Japan"
  email: "..."

co_authors:
  - name: "Sujana Kabiraj"
    affiliation: "Shiv Nadar University, India"
  - name: "Jiaqi Li"
    affiliation: "Nagoya University, Japan"

manuscript:
  title: "Regional growth, convergence, and spatial spillovers in India: A reproducible view from outer space"
  target_journal: "REGION — The Journal of ERSA"
  submission_type: "first"
```

For any field whose value is the literal string `"[PROMPT ON FIRST RUN]"` or
missing entirely, ask the user interactively:

> "The config file is missing `corresponding_author.email`. Please provide it
> so I can render the cover letter. I'll save it back to `.claude/author-config.yml`
> so future invocations are hands-off."

After the user provides a value, write it back to the file using Edit (not
Write, to preserve the other fields and comments). Do not proceed until every
required field has a real value.

**Required fields**: all entries under `corresponding_author`, at least one
entry under `co_authors`, and all three fields under `manuscript`.

## Phase 3: Anonymization audit

Scan `index.qmd` for identity-leak patterns using Grep. The patterns are
listed in the "Anonymization rules" section below. For each hit, report:

| # | File | Line | Matched pattern | Matched string |
|---|---|---|---|---|

Also scan the YAML front matter to confirm `author:` has `name: "Anonymous"`.
If it does not, flag this as a leak even if no pattern matched.

If the scan finds zero hits AND the YAML author is already `"Anonymous"`,
report "No identity leaks found in `index.qmd`" and skip to Phase 4.

If any hits are found, ask the user to choose:

- **Strategy A (default, recommended)**: I will create a temporary
  `index-blind.qmd` at the project root with the matched strings redacted
  per the replacement rules. The render and standalone HTML in Phases 4 and
  5 will use this temporary file. `index.qmd` will not be touched. The
  temporary file is deleted after Phase 6.
- **Strategy B**: Abort so the user can fix `index.qmd` by hand and re-run
  the skill.

Wait for the user's choice. If they pick A, copy `index.qmd` to
`index-blind.qmd` and apply each replacement. Record the source filename
(`index-blind.qmd` or `index.qmd`) — later phases will need to know which
one to render.

## Phase 4: Render

Run the full clean-render pipeline to ensure outputs are fresh. If Strategy A
is active, the render must operate on `index-blind.qmd`.

If Strategy A is active, temporarily swap the files:

```bash
mv index.qmd index-original.qmd
mv index-blind.qmd index.qmd
bash scripts/clean-render.sh
mv index.qmd index-blind.qmd
mv index-original.qmd index.qmd
```

The swap is necessary because `_quarto.yml` has `manuscript: article: index.qmd`
hard-coded; the clean-render pipeline does not accept a different source name.
Always restore the original `index.qmd` in a finally-style cleanup even if
the render fails.

If Strategy A is not active (no leaks found), just run:

```bash
bash scripts/clean-render.sh
```

After render, verify the expected outputs exist:

| Output | Path |
|---|---|
| HTML | `index.html` |
| REGION PDF | `index-REGION.pdf` |
| Standard PDF | `index.pdf` |
| Word | `index.docx` |

Verify the BibTeX warnings are exactly the three known-benign warnings:

- `chakravarty_dehejia_gst` page numbers missing (EPW Notes section has no page range)
- `glawe_mendez_china_luminosity` no number and no volume
- `glawe_mendez_china_luminosity` page numbers missing

If any new warnings appear or any citation is unresolved, stop and report.

## Phase 5: Generate standalone HTML

Run:

```bash
quarto render index.qmd --to html -M embed-resources:true --output manuscript-standalone.html
```

(Use `index-blind.qmd` as the source if Strategy A is active — but the
source file must be named `index.qmd` at render time, so apply the same
swap-and-restore trick from Phase 4.)

Verify:

| Check | How |
|---|---|
| File exists | `ls manuscript-standalone.html` |
| File is single-file (embed worked) | `test $(stat -f%z manuscript-standalone.html) -gt 5000000` (must be > 5 MB) |
| `index.html` not clobbered | Compare mtime to pre-render value |

If the file is smaller than 5 MB, the `embed-resources` flag silently failed
and the output is still referencing external assets. Stop and report.

## Phase 6: Assemble the bundle

Create the directory tree:

```bash
mkdir -p legacy/submission-YYYYMMDD/latex-manuscript/figures
```

Copy files in this exact order. Use `cp` for files that live outside the
bundle and will be copied. Use `mv` only for `manuscript-standalone.html`
which is a temporary file at the project root.

### Step 6.1 — Copy main output artifacts

```bash
cp index-REGION.pdf legacy/submission-YYYYMMDD/manuscript-REGION.pdf
cp index.docx legacy/submission-YYYYMMDD/manuscript.docx
mv manuscript-standalone.html legacy/submission-YYYYMMDD/manuscript-standalone.html
```

### Step 6.2 — Copy REGION template files with lowercase renames

Case matters on Linux and most submission servers. Two files in the
extension directory have uppercase names but are referenced by lowercase
strings in `regart.cls` and `index-REGION.tex`. Rename them when copying:

```bash
cp _extensions/region-ersa/REGION/regart.cls     legacy/submission-YYYYMMDD/latex-manuscript/regart.cls
cp _extensions/region-ersa/REGION/region.sty     legacy/submission-YYYYMMDD/latex-manuscript/region.sty
cp _extensions/region-ersa/REGION/REGION.bst     legacy/submission-YYYYMMDD/latex-manuscript/region.bst
cp _extensions/region-ersa/REGION/Titlepage_21.pdf legacy/submission-YYYYMMDD/latex-manuscript/titlepage_21.pdf
cp _extensions/region-ersa/REGION/Titlepage_22.pdf legacy/submission-YYYYMMDD/latex-manuscript/titlepage_22.pdf
cp _extensions/region-ersa/REGION/ERSA_logo.png  legacy/submission-YYYYMMDD/latex-manuscript/ERSA_logo.png
cp _extensions/region-ersa/REGION/wutext.pdf     legacy/submission-YYYYMMDD/latex-manuscript/wutext.pdf
cp _extensions/region-ersa/REGION/fwf.pdf        legacy/submission-YYYYMMDD/latex-manuscript/fwf.pdf
```

### Step 6.3 — Copy figures with short descriptive names

```bash
cp images/luminosity_map.png  legacy/submission-YYYYMMDD/latex-manuscript/figures/luminosity_map.png
cp images/luminosity_map2.png legacy/submission-YYYYMMDD/latex-manuscript/figures/luminosity_map2.png

cp index_files/figure-latex/notebooks-c02_regional_convergence_sc-fig-convergence-output-2.png legacy/submission-YYYYMMDD/latex-manuscript/figures/fig-convergence.png
cp index_files/figure-latex/notebooks-c03_spatial_dependence_lisa-fig-chorophleths-output-1.png     legacy/submission-YYYYMMDD/latex-manuscript/figures/fig-chorophleths.png
cp index_files/figure-latex/notebooks-c03_spatial_dependence_lisa-fig-wmatrix6nn-output-1.png       legacy/submission-YYYYMMDD/latex-manuscript/figures/fig-wmatrix6nn.png
cp index_files/figure-latex/notebooks-c03_spatial_dependence_lisa-fig-dependence-initial-output-1.png legacy/submission-YYYYMMDD/latex-manuscript/figures/fig-dependence-initial.png
cp index_files/figure-latex/notebooks-c03_spatial_dependence_lisa-fig-dependence-growth-output-1.png  legacy/submission-YYYYMMDD/latex-manuscript/figures/fig-dependence-growth.png
cp index_files/figure-latex/notebooks-c06_spatial_culture-fig-culture-scatter-output-1.png legacy/submission-YYYYMMDD/latex-manuscript/figures/fig-culture-scatter.png
cp index_files/figure-latex/notebooks-c06_spatial_culture-fig-culture-lisa-output-1.png    legacy/submission-YYYYMMDD/latex-manuscript/figures/fig-culture-lisa.png

cp _extensions/region-ersa/REGION/CC-BY-88x31.png legacy/submission-YYYYMMDD/latex-manuscript/figures/CC-BY-88x31.png
```

### Step 6.4 — Copy references.bib

```bash
cp references.bib legacy/submission-YYYYMMDD/latex-manuscript/references.bib
```

### Step 6.5 — Copy index-REGION.tex and rewrite figure paths

```bash
cp index-REGION.tex legacy/submission-YYYYMMDD/latex-manuscript/manuscript.tex
```

Then apply these ten exact-string Edit operations on
`legacy/submission-YYYYMMDD/latex-manuscript/manuscript.tex`. Each `old_string`
is a complete `\includegraphics{...}` path literal:

| Find | Replace |
|---|---|
| `{images/luminosity_map.png}` | `{figures/luminosity_map.png}` |
| `{images/luminosity_map2.png}` | `{figures/luminosity_map2.png}` |
| `{index_files/figure-latex/notebooks-c02_regional_convergence_sc-fig-convergence-output-2.png}` | `{figures/fig-convergence.png}` |
| `{index_files/figure-latex/notebooks-c03_spatial_dependence_lisa-fig-chorophleths-output-1.png}` | `{figures/fig-chorophleths.png}` |
| `{index_files/figure-latex/notebooks-c03_spatial_dependence_lisa-fig-wmatrix6nn-output-1.png}` | `{figures/fig-wmatrix6nn.png}` |
| `{index_files/figure-latex/notebooks-c03_spatial_dependence_lisa-fig-dependence-initial-output-1.png}` | `{figures/fig-dependence-initial.png}` |
| `{index_files/figure-latex/notebooks-c03_spatial_dependence_lisa-fig-dependence-growth-output-1.png}` | `{figures/fig-dependence-growth.png}` |
| `{index_files/figure-latex/notebooks-c06_spatial_culture-fig-culture-scatter-output-1.png}` | `{figures/fig-culture-scatter.png}` |
| `{index_files/figure-latex/notebooks-c06_spatial_culture-fig-culture-lisa-output-1.png}` | `{figures/fig-culture-lisa.png}` |
| `{_extensions/region-ersa/REGION/CC-BY-88x31}` | `{figures/CC-BY-88x31}` |

After the edits, verify by grepping for `\includegraphics` in the new
`manuscript.tex`: every result must point to `figures/...` and nothing else.

### Step 6.6 — Clean up temp files from Strategy A

If Strategy A is active, delete the temporary `index-blind.qmd` now that
it has been fully consumed:

```bash
rm -f index-blind.qmd
```

## Phase 7: Generate cover letter and READMEs

Three files to create, two of them blind. Generate each one, **show the
rendered content to the user**, and ask for explicit approval before writing
to disk. This is the option (b) interaction pattern from the plan: generate,
show, ask.

### Step 7.1 — `legacy/submission-YYYYMMDD/CoverLetter.md` (non-blind)

Render the cover letter template below by substituting placeholders from
`.claude/author-config.yml`. The `{DATE}` placeholder uses today's date in
long form (e.g., "April 10, 2026").

For `submission_type: "first"`, use the template as-is. For
`submission_type: "revision"`, replace the opening paragraph with a
revision-aware alternative (see the "Revision opening paragraph" section
after the template).

**Cover letter template (first submission):**

```markdown
# Cover Letter

**{DATE}**

Dear Editor,

REGION — The Journal of the European Regional Science Association

**Subject**: Submission of manuscript "{MANUSCRIPT_TITLE}"

Dear Editor,

On behalf of my co-authors, I am pleased to submit for your consideration the manuscript entitled "{MANUSCRIPT_TITLE}".
The paper extends the work of Chanda and Kabiraj (2020, *World Development*) on regional convergence across 520 Indian districts, examined through satellite nighttime lights data for the period 1996–2010, with three methodological contributions.

First, we develop an interactive visualization tool built on Google Earth Engine that enables researchers to explore spatial and temporal patterns of regional convergence directly from satellite imagery.
Second, we formally test for spatial dependence in both the dependent and independent variables of the convergence equations using Global Moran's I and Local Indicators of Spatial Association (LISA), and we find that spatial autocorrelation is a prominent feature of the regional convergence process in India.
Third, we estimate a spatial Durbin model that distinguishes direct effects of district characteristics from indirect spillover effects, and we show that accounting for these spatial channels increases the estimated total convergence effect by approximately 48 percent relative to conventional non-spatial estimates in our fully specified model.
This finding has a concrete policy implication: the benefits of place-based development interventions are likely larger than traditional estimates suggest because they propagate to neighboring districts through spatial multiplier effects.

Beyond its substantive and methodological contributions, the manuscript adopts a fully reproducible open-science workflow built on Jupyter notebooks (integrating Python, R, and Stata kernels) and the Quarto publishing system.
Every figure and table is traceable to a specific computational notebook, and the complete analytical pipeline — from raw satellite data to final regression tables — is publicly documented and re-executable.
We believe this combination of substantive findings, methodological innovation, and transparent reproducibility fits squarely within REGION's mission to publish rigorous, accessible, and computationally reproducible regional science research.
The manuscript is formatted using the official REGION LaTeX template.

The manuscript has not been published elsewhere and is not currently under consideration at any other journal.
All authors have read and approved the submitted version.
The authors declare no conflicts of interest.
Funding information is acknowledged in the manuscript but is omitted from the blinded reviewer copy in compliance with REGION's double-blind review policy.

We appreciate your consideration of our manuscript and look forward to the reviewers' feedback.
Please do not hesitate to contact me at the address below with any questions regarding the submission.

Sincerely,

**{CORRESPONDING_AUTHOR_NAME}**
{CORRESPONDING_AUTHOR_AFFILIATION}
{CORRESPONDING_AUTHOR_EMAIL}

On behalf of co-authors: **{CO_AUTHOR_1_NAME}** ({CO_AUTHOR_1_AFFILIATION}) and **{CO_AUTHOR_2_NAME}** ({CO_AUTHOR_2_AFFILIATION}).
```

**Revision opening paragraph (replace the first two paragraphs above when `submission_type: "revision"`):**

```markdown
On behalf of my co-authors, I am pleased to submit a revised version of the manuscript entitled "{MANUSCRIPT_TITLE}" (manuscript ID {MANUSCRIPT_ID}) in response to the reviewers' and editor's comments on our previous submission.
We are grateful for the constructive feedback, which has substantially improved the paper.
A detailed point-by-point response to every reviewer comment is provided in a separate response letter accompanying this submission.
The revisions include ...
```

For revisions, the skill should also prompt the user for `{MANUSCRIPT_ID}`
and the summary of changes; save a `{submission_type, manuscript_id, changes_summary}`
block to `.claude/author-config.yml` for future invocations if the user wants.

After substitution, show the rendered cover letter to the user and ask:

1. Accept and write to `legacy/submission-YYYYMMDD/CoverLetter.md`
2. Regenerate with different emphasis (prompt for which aspect to lead with)
3. Abort

### Step 7.2 — `legacy/submission-YYYYMMDD/README.md` (blind)

Generate from this template. Substitute `{DATE}`, `{MANUSCRIPT_TITLE}`,
`{FILE_COUNT}`, `{BUNDLE_SIZE_MB}`, and `{GIT_COMMIT_SHA}` (from `git rev-parse HEAD`).
**Never** substitute author names or repository URLs into this file.

```markdown
# Submission bundle — {DATE}

Self-contained submission bundle for the manuscript "{MANUSCRIPT_TITLE}".
Target venue: REGION — The Journal of ERSA.

This directory contains a frozen snapshot of all reviewer-facing submission artifacts.
Author identity has been removed from every file in this directory except `CoverLetter.md`, which is addressed to the editor and contains corresponding-author contact information.

## Contents

| File | Size | Purpose |
|---|---|---|
| `CoverLetter.md` | — | Correspondence to the editor (non-blinded). Contains author info; intended only for editorial reading. |
| `manuscript-REGION.pdf` | ~14 MB | Primary submission PDF, typeset with the REGION journal template (A4, author-year citations, line numbers). Blinded. |
| `manuscript.docx` | ~11 MB | Microsoft Word version of the manuscript. Blinded. |
| `manuscript-standalone.html` | ~20 MB | Single-file HTML version with all figures, math, CSS, and MathJax embedded. Opens in any browser without internet. Blinded. |
| `latex-manuscript/` | — | Self-contained LaTeX source tree. A reviewer can recompile the REGION PDF using only the files in this subdirectory. See `latex-manuscript/README.md` for compile instructions. Blinded. |

Bundle summary: {FILE_COUNT} files, total ~{BUNDLE_SIZE_MB} MB. Generated from source commit `{GIT_COMMIT_SHA}`.

## What this bundle does not contain

- **Computational notebooks.** The analysis notebooks are not duplicated here because the single-file HTML already embeds their rendered outputs. Reviewers who wish to inspect or re-execute the notebooks can follow the links inside `manuscript-standalone.html`, which point to the public repository from which this bundle was generated.
- **Raw data files.** Nighttime lights rasters and shapefiles are hosted alongside the notebooks at the original repository.
- **Quarto project configuration.** The `_quarto.yml`, `scripts/`, and `_extensions/` files that drive the build are not copied here; only the outputs they produce are.

## Verification performed before this bundle was committed

1. The standalone LaTeX tree was compiled from scratch using `lualatex` and `bibtex`. The resulting PDF matched the page count of `manuscript-REGION.pdf`.
2. A recursive grep over all reviewer-facing files (every file except `CoverLetter.md`) confirmed zero matches for author-identifying strings, grant numbers, author-owned URLs, or institutional affiliations.
3. PDF metadata fields (`/Author`, `/Title`, `/Subject`, `/Keywords`, `/Creator`) on `manuscript-REGION.pdf` were checked and confirmed not to contain identifying information.
```

Show to user and ask for approval.

### Step 7.3 — `legacy/submission-YYYYMMDD/latex-manuscript/README.md` (blind)

Generate from this template. Never substitute author names or specific
repository URLs:

```markdown
# Standalone LaTeX source

This directory contains a self-contained LaTeX source tree for the manuscript "{MANUSCRIPT_TITLE}".
Everything needed to recompile the REGION journal PDF is present in this folder.
No files from outside this directory are required at compile time.

## Contents

| File / directory | Purpose |
|---|---|
| `manuscript.tex` | Main LaTeX source. |
| `references.bib` | BibTeX bibliography. |
| `regart.cls` | REGION journal document class. |
| `region.sty` | REGION journal style package. |
| `region.bst` | REGION bibliography style. Renamed from `REGION.bst` to match `\bibliographystyle{region}` on case-sensitive filesystems. |
| `titlepage_21.pdf`, `titlepage_22.pdf` | Title page graphics referenced by `regart.cls`. Renamed from uppercase `Titlepage_*.pdf` for case-sensitive filesystems. |
| `ERSA_logo.png`, `wutext.pdf`, `fwf.pdf` | Publisher, university, and funder logos referenced by `regart.cls`. |
| `figures/` | All figures included in the manuscript body. |

## How to compile

Requires a TeX Live Full distribution (or equivalent) with these packages installed: `parnotes`, `lineno`, `fancyhdr`, `draftwatermark`, `natbib`, `hyperref`, `multirow`, `longtable`, `booktabs`, `graphicx`, `amsmath`, `amssymb`, `lmodern`.
All of these ship with TeX Live Full.

From inside this directory, run:

    lualatex manuscript.tex
    bibtex manuscript
    lualatex manuscript.tex
    lualatex manuscript.tex
    lualatex manuscript.tex

The REGION template requires four `lualatex` passes (not the usual three) because the format uses line numbers and marginal cross-references that take an extra pass to stabilize.
The output is `manuscript.pdf`.

`pdflatex` also works if you prefer it over `lualatex`; the preamble detects the engine automatically.

## Troubleshooting

- **Missing package errors**: install TeX Live Full, or `tlmgr install <package>` for the specific missing package.
- **Missing figure errors**: confirm the `figures/` directory is present and contains every image referenced in `manuscript.tex`. The paths are relative; do not rename the directory.
- **Missing `regart.cls`**: the document class begins with `\documentclass[...]{article}` and then loads `regart` via `\usepackage{region,...}`. Both `regart.cls` and `region.sty` must be present in the same directory as `manuscript.tex`.
- **Bibliography style errors**: confirm `region.bst` (lowercase) is present.

## Provenance

This tree is a frozen snapshot of the source manuscript at the point of submission.
The figures were produced by computational notebooks that accompany the manuscript in its original repository, and then embedded into the Quarto manuscript via `{{< embed >}}` shortcodes.
This standalone tree contains only the pre-rendered images.
```

Show to user and ask for approval.

## Phase 8: Verification (three-gate)

All three gates must pass. If any fails, stop and report; do not attempt to
auto-fix.

### Gate 8.1 — Standalone LaTeX compilation

From `legacy/submission-YYYYMMDD/latex-manuscript/`, run four lualatex passes
interleaved with one bibtex pass. Use absolute paths in `cd` commands so the
Bash shell state does not get confused:

```bash
cd /absolute/path/to/legacy/submission-YYYYMMDD/latex-manuscript
lualatex -interaction=nonstopmode -halt-on-error manuscript.tex
bibtex manuscript
lualatex -interaction=nonstopmode -halt-on-error manuscript.tex
lualatex -interaction=nonstopmode -halt-on-error manuscript.tex
lualatex -interaction=nonstopmode -halt-on-error manuscript.tex
```

After the fourth pass, verify `manuscript.pdf` exists and matches the page
count of `legacy/submission-YYYYMMDD/manuscript-REGION.pdf`. A byte-exact
size match is a strong signal the content is identical (only timestamp
metadata differs). If the sizes differ by more than 1%, investigate before
proceeding.

Then clean up intermediate build artifacts — **but keep nothing in the
tree that a reviewer might find confusing**:

```bash
rm -f legacy/submission-YYYYMMDD/latex-manuscript/manuscript.aux \
      legacy/submission-YYYYMMDD/latex-manuscript/manuscript.log \
      legacy/submission-YYYYMMDD/latex-manuscript/manuscript.out \
      legacy/submission-YYYYMMDD/latex-manuscript/manuscript.bbl \
      legacy/submission-YYYYMMDD/latex-manuscript/manuscript.blg \
      legacy/submission-YYYYMMDD/latex-manuscript/manuscript.toc \
      legacy/submission-YYYYMMDD/latex-manuscript/manuscript.pdf
```

The generated `manuscript.pdf` is deliberately deleted: the bundle ships
only the source tree, not a pre-built PDF. The primary PDF is
`manuscript-REGION.pdf` at the bundle root.

### Gate 8.2 — Blindness grep

Recursively search all reviewer-facing files for identity-leak patterns.
Exclude `CoverLetter.md` from the scan.

Use Grep with `path: legacy/submission-YYYYMMDD/` and these rules:

1. **Author surname scan**: search for each surname from
   `.claude/author-config.yml` as a whole-word match in
   `*.tex`, `*.md` (except `CoverLetter.md`), `*.html`, `*.txt`, `*.yml`, `*.yaml`.
   Bibliography entries in `references.bib` are excluded because third-person
   self-citations are acceptable under REGION's blind-review policy — but
   all other files must have zero matches.
2. **Grant number scan**: search for `Grant Number`, `KAKENHI`, and generic
   grant patterns across all files except `CoverLetter.md` and `references.bib`.
3. **Author-owned URL scan**: search for `bit\.ly/`, `quarcs-lab`,
   `github\.com/[\w-]+/[\w-]+` across all files except `CoverLetter.md`
   and `references.bib`.
4. **Personal email scan**: search for `[\w.+-]+@[\w.-]+\.[\w.-]+` across
   all files except `CoverLetter.md`.

Zero matches is a pass. Any match is a fail. Report the `file:line` of each
match and ask the user to decide: update `index.qmd` and re-run, or add the
specific string to the exceptions list below, or accept and proceed anyway.

### Gate 8.3 — PDF metadata check

Check `legacy/submission-YYYYMMDD/manuscript-REGION.pdf` for identifying
metadata. Use `pdfinfo` if available:

```bash
pdfinfo legacy/submission-YYYYMMDD/manuscript-REGION.pdf
```

If `pdfinfo` is not installed, fall back to a Python one-liner:

```bash
uv run python -c "from pypdf import PdfReader; r = PdfReader('legacy/submission-YYYYMMDD/manuscript-REGION.pdf'); print(r.metadata)"
```

Check these fields:

- `/Author`
- `/Title`
- `/Subject`
- `/Keywords`
- `/Creator`
- `/Producer`

For each author surname from `.claude/author-config.yml`, the metadata must
not contain it. `/Title` may contain the manuscript title (that's fine, it
doesn't identify authors). `/Creator` and `/Producer` often name the TeX
engine (e.g., `LaTeX with hyperref`) — that's fine.

If any author name appears, report the leak and suggest:

```bash
exiftool -Author= -Title= -Subject= -Keywords= manuscript-REGION.pdf
```

Do not run the `exiftool` command without explicit user approval — it
modifies the PDF in place.

Also check `manuscript.docx` using `unzip -p <file> docProps/core.xml | grep -i creator`
or a Python one-liner with `python-docx`. DOCX files embed author info from
`git config user.name` and Microsoft Office defaults; the blinded render
should strip these, but verify.

## Phase 9: Summary and stop

Present a summary table to the user:

| Item | Value |
|---|---|
| Bundle path | `legacy/submission-YYYYMMDD/` |
| Source commit | `{git rev-parse HEAD}` |
| File count | {count} |
| Total size | {size} MB |
| Anonymization strategy | {A or N/A} |
| Compilation check | PASS ({pages} pages) |
| Blindness grep | PASS (0 matches) |
| PDF metadata check | PASS |
| Cover letter | `legacy/submission-YYYYMMDD/CoverLetter.md` (non-blind, for editor) |

Then, **do not commit**. Tell the user:

> "Bundle is ready and verified. The skill does not commit or push — please
> review the files in `legacy/submission-YYYYMMDD/` and then run your
> normal git workflow to stage and commit the bundle. For example:
>
>     git add legacy/submission-YYYYMMDD/
>     git status
>     git commit -m \"Add REGION submission bundle YYYY-MM-DD\"
>     git push
>
> Note: `CoverLetter.md` contains author info and is only for the editor —
> do not distribute it to reviewers."

The skill stops here. Do not run `git` commands.

## Anonymization rules

### Patterns to redact

Applied in Phase 3 (scan of `index.qmd`) and Phase 8.2 (verification scan
of the bundle). Each pattern has a case-insensitive regex and a standard
replacement string.

| Pattern (regex) | Replacement | Why |
|---|---|---|
| `JSPS KAKENHI Grant Number\s+\w+` | `[Funding details redacted for blind review]` | Grant numbers resolve to PIs via public databases |
| `(Grant\|Award) (No\.\|Number)\s+[A-Z0-9-]+` | `[Funding details redacted for blind review]` | Generic grant number pattern |
| `bit\.ly/[a-zA-Z0-9_-]+` | `[URL redacted for blind review]` | Link shorteners resolve to author-owned domains |
| `github\.com/[\w-]+/[\w-]+` | `[Repository URL redacted for blind review]` | Repo URLs name the user or org |
| `quarcs-lab\.github\.io\|quarcslab\.github\.io` | `[Repository URL redacted for blind review]` | Project Pages URL that names the lab |
| `[\w.+\-]+@[\w\-]+\.[\w.\-]+` (outside `CoverLetter.md`) | Flag for manual review | Personal email pattern |
| Author surnames loaded from `.claude/author-config.yml` | Flag for manual review | Direct author identification |

### Patterns NOT to redact

These look suspicious but are explicitly acceptable in blind review:

- **Third-person citations to self-authored published work**: e.g.,
  `@glawe_mendez_china_luminosity`, `@mendez_patnaik_notebook`, and their
  rendered forms like `Mendez (2023)` or `Mendez and Santos (2024)`. Most
  journal policies, including REGION's, accept third-person self-citation.
- **Generic tool mentions**: `Claude Code`, `Google Earth Engine`, `Quarto`,
  `GitHub` as a platform name (without a specific URL).
- **Data-source citations**: `Chanda and Kabiraj (2020)`,
  `Henderson et al. (2012)` — these are legitimate prior-work references.
- **Author surnames appearing inside `references.bib`** as part of
  legitimate citation keys or `author = { ... }` fields for cited works.
  The blindness grep must scope its surname check to exclude
  `references.bib`.

### Exceptions list

Specific strings known to be safe despite matching a redaction pattern.
Extend this list in a follow-up edit of SKILL.md if a false positive is
discovered in practice.

| String | Why it is safe |
|---|---|
| `@chanda_kabiraj_district_convergence` (and text renderings) | Legitimate third-person citation to a prior published paper |
| `Chanda and Kabiraj (2020)` | Same |
| `Mendez (2023)` or similar in bibliography | Third-person self-citation is acceptable under REGION blind-review policy |
| `Kabiraj` inside `references.bib` | Bibliography field, not body text |

## Testing

Four tests the user can run to verify the skill works end-to-end. Each test
should leave the repository in the same state it was in before the test.

### Test 1: Smoke test

Invoke `/prepare-region-submission` on a clean working tree. Expected:

- Bundle is created at `legacy/submission-YYYYMMDD/` with 26 files
  (4 top-level + 22 in `latex-manuscript/`)
- Standalone LaTeX compiles in Phase 8.1
- Blindness grep passes in Phase 8.2
- PDF metadata check passes in Phase 8.3
- User is shown the summary table in Phase 9
- No state outside the bundle is modified (no commits, no pushes)

### Test 2: Leak-injection test

Add a fake string like `Grant Number XYZ-12345` to the `## Acknowledgments`
section of `index.qmd`. Invoke the skill. Expected:

- Phase 3 flags the line and offers redaction
- After choosing Strategy A, the rendered `manuscript-REGION.pdf` in the
  bundle does not contain the string
- The temporary `index-blind.qmd` is deleted in Step 6.6

Revert `index.qmd` after the test.

### Test 3: Compilation-failure test

Temporarily break a figure path in `manuscript.tex` inside the bundle
after Phase 6 completes. Re-run Phase 8 manually. Expected:

- Phase 8.1 catches the compilation failure
- The skill halts before reporting success
- The incomplete bundle is left in place for inspection

### Test 4: Existing-folder test

Invoke the skill twice in a row on the same day. Expected:

- The second invocation detects that `legacy/submission-YYYYMMDD/` already
  exists and refuses to overwrite without explicit user confirmation

## Important reminders

- Always use relative paths from the project root in Bash commands
  (`index.qmd`, not `/Users/.../project2025s/index.qmd`)
- After any `cd` in a Bash command, the shell state persists across
  subsequent Bash calls in the same session — prefer absolute paths or
  return to the project root explicitly to avoid surprises
- Do NOT use `git add -A` — stage files explicitly
- Do NOT attempt to modify `_quarto.yml` or `index.qmd` permanently
- Do NOT commit or push — always stop at Phase 9 and let the user handle git
