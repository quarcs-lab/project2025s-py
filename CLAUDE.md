# CLAUDE.md – AI Assistant Instructions

**READ THIS FILE FIRST** upon entering this project. These rules are non-negotiable.

---

## Critical Rules

### 1. NEVER DELETE DATA OR PROGRAMS

Never delete any data or program files. Protected formats:

- **Data:** `.dta`, `.sav`, `.sas7bdat`, `.xlsx`, `.xls`, `.csv`, `.tsv`, `.shp`, `.geojson`, `.kml`, `.gpkg`, `.db`, `.sqlite`, `.sql`, `.txt`, `.json`, `.xml`, `.parquet`
- **Programs:** `.do`, `.R`, `.py`, `.jl`, `.m`, `.ipynb`, `.Rmd`, `.qmd`, `.yaml`, `.yml`, `.toml`, `.ini`, `.md`, `.tex`

### 2. LEGACY FOLDER IS SACRED

The `./legacy/` folder is a read-only snapshot of the original project (created 20260120). Never modify it.

### 3. COPY, DON'T MOVE

- COPY from `./legacy/` when you need original files
- COPY between working directories if needed
- NEVER move files between directories

### 4. STAY WITHIN THIS DIRECTORY

All work must remain within this project directory. Never go up out of this folder.

### 5. MAINTAIN PROGRESS LOGS

The `./log/` directory preserves context across sessions (chat sessions can die unexpectedly).

**When:** After significant work, before ending a session, after major decisions.

**How:** Create `./log/YYYYMMDD_HHMM.md` entries with: current state, work summary (include key results/tables/figures), decisions made, issues/blockers, next steps.

**On startup:** Always check `./log/` for recent entries.

---

## Project Context

- **Title:** Spatial Convergence Analysis of Nighttime Lights in India (1996-2010)
- **Authors:** Carlos Mendez, Sujana Kabiraj, Jiaqi Li
- **Tools:** Quarto, Python, Claude Code (all computational notebooks are Python; original R/Stata sources retained in `archive/` and `legacy/*.zip` for provenance)
- **Python Package Manager:** [uv](https://docs.astral.sh/uv/)
- **Goal:** Reproducible research using Quarto's single-source publishing paradigm

### Python Environment (uv)

Dependencies declared in `pyproject.toml` (source of truth), locked in `uv.lock`.

**Key files:** `pyproject.toml`, `uv.lock`, `.python-version` (Python 3.10), `requirements.txt` (Colab compat only)

```bash
uv sync                    # Create .venv/ and install all dependencies
uv add <package>           # Add a dependency (NOT pip install)
uv run python script.py    # Run in project venv
```

**Rules:** Use `uv add` for new packages (not `pip install`). Always use `uv run` for execution. Never commit `.venv/`.

### Jupytext (Notebook <-> Script Pairing)

Each notebook in `notebooks/` is paired with a MyST Markdown `.md` file via [Jupytext](https://jupytext.readthedocs.io/).

| Notebook | Paired `.md` | Language |
|----------|-------------|----------|
| `c01_view_from_space.ipynb` | `c01_view_from_space.md` | Python |
| `c02_regional_convergence_sc.ipynb` | `c02_regional_convergence_sc.md` | Python |
| `c03_spatial_dependence_lisa.ipynb` | `c03_spatial_dependence_lisa.md` | Python |
| `c04_spillover_modeling_6nn.ipynb` | `c04_spillover_modeling_6nn.md` | Python |
| `c05_spatial_culture.ipynb` | — (no Jupytext pair) | Python |
| `c06_spatial_culture.ipynb` | — (no Jupytext pair) | Python |

```bash
uv run jupytext --sync notebooks/<file>   # Sync .md <-> .ipynb
```

- Prefer editing the `.md` file, then sync and re-execute to regenerate outputs
- Cell outputs are stored only in `.ipynb`; `.md` files contain just code and markdown

---

## Workflow

### Single-Source Authoring

Write in **ONE file** (`index.qmd`). Quarto generates all outputs:

| Output | Description |
|--------|-------------|
| `index.pdf` | Standard PDF (Letter, KOMA-Script, numeric citations) |
| `index-REGION.pdf` | REGION journal PDF (A4, author-year, line numbers) |
| `index.html` | Interactive web version (GitHub Pages) |
| `index.docx` | Microsoft Word |

**The workflow is intentionally simple:**

```text
Edit index.qmd -> Run "bash scripts/clean-render.sh" -> All outputs generated
```

**DO NOT complicate this workflow.**

### Manuscript Formatting (`index.qmd`)

- **One sentence per line** — each sentence starts on its own line (improves git diffs and collaborative editing)
- **Blank lines** separate paragraphs and sections
- **Exception:** Figure/table captions and YAML frontmatter may contain multiple sentences on one line

### How Notebooks Feed Into the Manuscript

- Notebooks registered in `_quarto.yml` under `manuscript.notebooks`
- `index.qmd` uses `{{< embed >}}` shortcodes to pull labeled figures/tables
- `freeze: auto` re-executes only changed notebooks

Current embeds:
```
{{< embed notebooks/c02_regional_convergence_sc.ipynb#fig-convergence >}}
{{< embed notebooks/c03_spatial_dependence_lisa.ipynb#fig-chorophleths >}}
{{< embed notebooks/c03_spatial_dependence_lisa.ipynb#fig-Wmatrix6nn >}}
{{< embed notebooks/c03_spatial_dependence_lisa.ipynb#fig-dependence-initial >}}
{{< embed notebooks/c03_spatial_dependence_lisa.ipynb#fig-dependence-growth >}}
{{< embed notebooks/c04_spillover_modeling_6nn.ipynb#tbl-models >}}
{{< embed notebooks/c06_spatial_culture.ipynb#fig-culture-scatter >}}
{{< embed notebooks/c06_spatial_culture.ipynb#fig-culture-lisa >}}
```

### Updating Notebooks

1. Edit notebook source in `notebooks/`
2. Run `bash scripts/clean-render.sh`

### Adding a New Notebook

1. Create `.qmd` or `.ipynb` in `notebooks/`
2. Add to `manuscript.notebooks` in `_quarto.yml`
3. Add `{{< embed >}}` references in `index.qmd`
4. Run `bash scripts/clean-render.sh`

### Notebook Execution Metadata (IMPORTANT)

`jupyter execute --inplace` injects `_sphinx_cell_id` and `execution` timestamps into cell metadata. Quarto renders these as raw HTML div attributes, polluting both the manuscript and notebook preview pages. **Always strip metadata after execution, before render:**

```python
import json
with open('notebooks/NOTEBOOK.ipynb') as f:
    nb = json.load(f)
for cell in nb['cells']:
    for key in list(cell.get('metadata', {}).keys()):
        if key in ('_sphinx_cell_id', 'execution', 'scrolled'):
            del cell['metadata'][key]
with open('notebooks/NOTEBOOK.ipynb', 'w') as f:
    json.dump(nb, f, indent=1)
```

**Quarto cell labels (`#| label:`) must be the FIRST line** of a code cell — no imports or blank lines before them, or `{{< embed >}}` will fail with "cell does not exist."

### Cache Architecture

**Cache (safe to delete, regenerated by render):**
- `_freeze/` — execution results (figures + JSON)
- `.quarto/embed/` — internal embed cache
- `notebooks/*.out.ipynb` — executed notebook intermediates (stale copies cause label mismatches)

**Output (commit for GitHub Pages):**
- `notebooks/*-preview.html` — rendered notebook pages for HTML sidebar
- `notebooks/*.embed-preview.html` — embedded preview pages

`freeze: auto` only handles `_freeze/`. The other caches are NOT auto-invalidated. **Always use `bash scripts/clean-render.sh` after notebook edits.**

Preview pages are only generated during a full `quarto render` (no `--to` flags).

### Important Warnings

- **Python 3.10 f-strings** cannot nest quotes or contain backslashes inside expressions. Use `.format()` for complex formatting.
- **Do NOT** change `freeze: auto` to `freeze: true`
- **Do NOT** render notebooks in isolation as a substitute for manuscript render
- **Do NOT** use plain `quarto render index.qmd` after notebook changes (embed cache not invalidated)
- **Do NOT** manually delete individual cache files — use `scripts/clean-render.sh`
- **Do NOT** render all formats with a single `quarto render` — this silently degrades the REGION PDF (2 LaTeX passes instead of required 4). The script renders each PDF separately.
- **Compilation errors?** Check [Quarto docs](https://quarto.org/docs/) and [GitHub Issues](https://github.com/quarto-dev/quarto-cli/issues) first. Verify version with `quarto --version`.

---

## REGION Extension Quick Reference

Format identifier: `region-ersa/REGION-pdf` (NOT `region-ersa/REGION/pdf` or `REGION-pdf`)

```yaml
# Correct _quarto.yml configuration
format:
  region-ersa/REGION-pdf:
    keep-tex: true
    docstatus: review          # review | final | uncorrected
    output-file: index-REGION
```

For detailed troubleshooting: [docs/region-troubleshooting.md](docs/region-troubleshooting.md)

---

## Skills (Slash Commands)

The `.claude/skills/` directory contains reusable workflows invoked as slash commands:

| Command | Purpose |
|---------|---------|
| `/render` | Clean-render all manuscript outputs (HTML, PDF, REGION PDF, DOCX) |
| `/proofread` | Academic tone audit with structured report and approval workflow |
| `/bibtex-check` | Audit cited references for completeness; DOI-based metadata lookup |
| `/sync-notebooks` | Sync Jupytext `.md` <-> `.ipynb` pairs |
| `/log-progress` | Create a timestamped session log in `./log/` |
| `/one-sentence-per-line` | Reformat `index.qmd` to enforce one sentence per line |
| `/prepare-region-submission` | Freeze a blind, self-contained submission bundle at `legacy/submission-YYYYMMDD/` with REGION PDF, DOCX, standalone HTML, standalone LaTeX tree, and a non-blind cover letter for the editor |

---

## Session Checklist

**Start:** Check `./log/` for recent entries. **End:** Write `./log/YYYYMMDD_HHMM.md`. **Always:** Copy, don't move. When in doubt, ask.
