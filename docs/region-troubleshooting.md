# REGION Extension Troubleshooting

Detailed reference for diagnosing and fixing REGION journal template issues. For quick reference, see `CLAUDE.md`.

---

## Understanding Format Identifiers

Extension format identifiers are NOT obvious from directory structure.

- **Extension directory**: `_extensions/region-ersa/REGION/`
- **Format identifier**: `region-ersa/REGION-pdf` (NOT `region-ersa/REGION/pdf` or `region-ersa/pdf`)
- **Why**: Extensions define custom format names in `_extension.yml` under `contributes.formats:`

Verify before modifying `_quarto.yml`:

```bash
cat _extensions/region-ersa/REGION/_extension.yml | grep -A10 "contributes"
```

---

## Diagnosing Template Application Issues

**Problem:** PDFs compile successfully but template features are missing (no line numbers, wrong citation style, no branding).

**Silent Fallback:** Quarto silently falls back to default format when it can't find the specified format.

**Diagnostic Checklist:**

1. **Check bibliography style in logs:**
   ```bash
   quarto render index.qmd --to region-ersa/REGION-pdf 2>&1 | grep "bst"
   # Should show: region.bst
   ```

2. **Count LaTeX passes:**
   ```bash
   quarto render index.qmd --to region-ersa/REGION-pdf 2>&1 | grep "lualatex"
   # REGION: 4 passes. Standard: 2.
   ```

3. **Verify template packages in LaTeX source:**
   ```bash
   grep "usepackage{region}" index.tex
   # Should show: \usepackage{region,hyperref,multirow}
   ```

4. **Check documentclass:**
   ```bash
   grep "documentclass" index.tex
   # REGION: \documentclass[a4paper, twoside, review]{article}
   # Standard: \documentclass[...]{scrartcl}
   ```

5. **Visual markers in PDF:**
   - Line numbers on left margin (page 2+)
   - Citation style: (Author YYYY) vs [1]
   - ERSA logo and ISSN in footer

---

## Common Configuration Errors

### Wrong format identifier

```yaml
# WRONG
format:
  region-ersa/REGION/pdf:    # Too many path segments
  REGION-pdf:                # Missing namespace

# CORRECT
format:
  region-ersa/REGION-pdf:
    keep-tex: true
    docstatus: review
    output-file: index-REGION
```

### Incompatible options

- Start with minimal options, add incrementally
- Valid `docstatus` values: `review`, `final`, `uncorrected`

### Missing output-file

Both PDF formats need distinct `output-file` values to avoid overwriting each other.

---

## Debugging Workflow

1. **Enable keep-tex** in `_quarto.yml`:
   ```yaml
   region-ersa/REGION-pdf:
     keep-tex: true
   ```

2. **Clean and rebuild**:
   ```bash
   rm -f index*.pdf index*.tex
   rm -rf .quarto/
   quarto render index.qmd
   ```

3. **Inspect LaTeX source**:
   ```bash
   grep -E "(documentclass|usepackage\{region\}|bibliographystyle)" index.tex
   ```

4. **Compare checksums** (necessary but not sufficient):
   ```bash
   md5 index.pdf index-REGION.pdf
   ```

5. **Visual verification** (most reliable): open both PDFs side-by-side.

---

## Why Render PDF Formats Separately

When Quarto renders all formats at once, the REGION PDF gets only 2 lualatex passes instead of the required 4. This breaks natbib/region.bst citation processing and can produce identical-looking PDFs.

The `scripts/clean-render.sh` script handles this:

```bash
# REGION first (4 LaTeX passes for natbib/region.bst)
quarto render index.qmd --to region-ersa/REGION-pdf
mv index.tex index-REGION.tex   # Quarto always writes to index.tex

# Standard PDF (2 passes, scrartcl/letter)
quarto render index.qmd --to pdf

# Other formats (no conflict)
quarto render index.qmd --to html --to docx
```

### Verification

| Check | REGION (`index-REGION`) | Standard (`index`) |
|-------|------------------------|-------------------|
| Page size | A4 (595 x 842 pts) | Letter (612 x 792 pts) |
| LaTeX passes | 4 | 2 |
| Document class | `article` | `scrartcl` |
| Bibliography | `region.bst` (author-year) | numeric |
| Line numbers | Yes (review mode) | No |

```bash
# Verify page sizes
mdls -name kMDItemPageHeight -name kMDItemPageWidth index-REGION.pdf index.pdf

# Verify LaTeX sources are distinct
grep "documentclass" index-REGION.tex   # article, a4paper
grep "documentclass" index.tex          # scrartcl, letterpaper
```

---

## Prevention Checklist

Before reporting template issues:

- [ ] Format identifier matches `_extension.yml`
- [ ] Compilation logs show correct bibliography style
- [ ] 4 LaTeX passes confirmed for REGION
- [ ] LaTeX source inspected with `keep-tex: true`
- [ ] PDF has visual template markers (line numbers, branding)
- [ ] Both PDFs compared side-by-side

## Reference

- [log/20260205_1245_fix_region_template.md](../log/20260205_1245_fix_region_template.md) - Troubleshooting history
- [_extensions/region-ersa/REGION/_extension.yml](../_extensions/region-ersa/REGION/_extension.yml) - Extension config
- [_quarto.yml](../_quarto.yml) - Project format configuration
