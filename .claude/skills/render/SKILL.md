---
name: render
description: >
  This skill should be used when the user asks to "render", "build",
  "compile", "rebuild", or "generate outputs" for the manuscript.
  Also use when the user mentions Quarto rendering, PDF generation,
  or "clean render". Runs the full clean-render pipeline that produces
  HTML, Standard PDF, REGION PDF, and DOCX outputs.
---

# Render Manuscript

Run the clean-render script from the project root:

```bash
bash scripts/clean-render.sh
```

The script performs these steps:
1. Clear all Quarto caches (`_freeze/`, `.quarto/embed/`, notebook intermediates)
2. Full manuscript render (HTML + notebook previews + all formats)
3. Re-render REGION PDF with 4 LaTeX passes (required for natbib/region.bst)
4. Re-render Standard PDF (restores index.tex as standard LaTeX)

After the render completes, report the status of each output:

| Output | File | Status |
|--------|------|--------|
| HTML | `index.html` | OK / ERROR |
| REGION PDF | `index-REGION.pdf` | OK / ERROR |
| Standard PDF | `index.pdf` | OK / ERROR |
| Word | `index.docx` | OK / ERROR |

If any step fails, show the relevant error output and suggest a fix.

## Important

- Always run from the project root directory
- Do NOT use `quarto render` directly — the script handles the multi-pass pipeline
- Do NOT change `freeze: auto` to `freeze: true`
