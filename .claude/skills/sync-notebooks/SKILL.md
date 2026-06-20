---
name: sync-notebooks
description: >
  This skill should be used when the user asks to "sync notebooks",
  "sync jupytext", "update notebooks", "pair notebooks", or mentions
  syncing .ipynb and .md files. Also use when the user edits a notebook
  markdown file and needs to regenerate the .ipynb. Syncs Jupytext
  paired notebook (.ipynb) and MyST Markdown (.md) files.
---

# Sync Notebooks

The project has 4 paired notebooks:

| Notebook | Paired `.md` | Language |
|----------|-------------|----------|
| `c01_view_from_space.ipynb` | `c01_view_from_space.md` | Python |
| `c02_regional_convergence_sc.ipynb` | `c02_regional_convergence_sc.md` | R |
| `c03_spatial_dependence_lisa.ipynb` | `c03_spatial_dependence_lisa.md` | Python |
| `c04_spillover_modeling_6nn.ipynb` | `c04_spillover_modeling_6nn.md` | Stata |

## Sync all notebooks

```bash
uv run jupytext --sync notebooks/c01_view_from_space.ipynb
uv run jupytext --sync notebooks/c02_regional_convergence_sc.ipynb
uv run jupytext --sync notebooks/c03_spatial_dependence_lisa.ipynb
uv run jupytext --sync notebooks/c04_spillover_modeling_6nn.ipynb
```

## Sync a specific notebook

If the user specifies a notebook (by name or number like "c01", "c03"), sync only that one.

## Guidelines

- Always use `uv run jupytext --sync` (not plain `jupytext`)
- The `.md` files use MyST Markdown format
- Cell outputs are stored only in `.ipynb`; `.md` files contain just code and markdown
- Prefer editing the `.md` file, then syncing to regenerate the `.ipynb`
- After syncing, consider running `bash scripts/clean-render.sh` if the notebooks feed into the manuscript
