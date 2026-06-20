# Blind Peer Review — Original Author Information

**Date:** 2026-03-04
**Purpose:** Preserve author-identifying information removed for blind peer review.
**Restore after:** Review process is complete.

---

## Original Author Block (index.qmd, lines 5–26)

```yaml
# REGION-compatible author format
author:
  - name: "Carlos Mendez"
    affiliations:
      - name: "Nagoya University"
        city: "Nagoya"
        country: "Japan"
    orcid: "0000-0001-7978-2815"
    email: "carlosmendez777@gmail.com"
    corresponding: true
  - name: "Sujana Kabiraj"
    affiliations:
      - name: "Shiv Nadar University"
        city: "Greater Noida"
        country: "India"
    orcid: "0000-0002-3844-1197"
  - name: "Jiaqi Li"
    affiliations:
      - name: "Nagoya University"
        city: "Nagoya"
        country: "Japan"
    orcid: "0000-0002-8888-1234"
```

## Original Repository URL (index.qmd, line 534)

```
All data and computational code used in this study are available in the project repository: <https://github.com/quarcs-lab/project2025s>.
```

---

## Restoration Instructions

1. Replace `author: - name: "Anonymous"` with the full author block above
2. Replace `[Repository URL removed for blind review]` with `<https://github.com/quarcs-lab/project2025s>`
3. Re-render: `bash scripts/clean-render.sh`
