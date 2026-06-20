---
name: proofread
description: >
  This skill should be used when the user asks to "proofread", "proofread manuscript",
  "check writing", "edit tone", "academic tone check", "humanize text", or "check for
  AI writing". Also use when the user mentions proofreading, tone consistency, or
  removing AI-sounding language from the manuscript. Performs a systematic proofreading
  pass on the manuscript using a checklist derived from academic economics writing standards.
---

# Academic Manuscript Proofreading

## Role

Act as a conservative academic economist and professional copywriter. The target tone is formal, measured, and appropriately hedged. Never exaggerate claims. When in doubt, hedge more rather than less.

## Target file

The manuscript is `index.qmd` in the project root. Read the entire file before making any edits.

## Proofreading checklist

Work through each category in order. For each category, use Grep to search for the watchlist patterns, read surrounding context, and propose specific edits.

### C1: Overused words

Search for words that appear 4 or more times. Propose varied alternatives to reduce repetition, keeping the original where it fits best (typically 2-3 instances maximum).

**Common offenders:**

| Word | Alternatives |
|------|-------------|
| substantial/substantially | considerably, markedly, notably, appreciably, meaningfully |
| highlight/highlighting | illustrate, show, reveal, indicate, demonstrate |
| facilitate/facilitates | support, enable, help, allow, simplify |
| particularly | especially, notably, in particular |
| enable/enables | allow, permit, support, make possible |
| underscore | illustrate, reinforce, confirm |
| leverage | use, employ, draw on, build on |
| moreover/furthermore | additionally, also, in addition, [or restructure to eliminate] |
| crucial/critical | important, key, central, essential |

**How to check:** Run `grep -c` for each word in `index.qmd`. Flag any appearing 4+ times. Propose replacements for all but 2-3 of the strongest uses.

### C2: AI-sounding phrases

Flag and replace formulaic transitions and constructions that signal AI-generated text. These phrases are not wrong, but their clustering makes the writing feel mechanical.

**Watchlist (flag if found):**

- "Importantly," (sentence opener)
- "Taken together,"
- "These findings have important implications"
- "It is worth noting that"
- "plays a crucial/critical/vital role"
- "highlight(s) the value of"
- "underscore(s) the importance of"
- "offers/provides a [powerful/robust/comprehensive/valuable] framework"
- "created new opportunities"
- "paving the way for"
- "sheds light on"
- "a testament to"
- "In this context," (weak connector)
- "It should be noted that"

**Replacements:** Use direct, specific language. Remove the filler phrase and start with the substantive content. For example:
- "Importantly, X reveals..." -> "X also reveals..." or just "X reveals..."
- "These findings have important implications for..." -> "The findings carry implications for..." or start directly with the implication
- "It is worth noting that X" -> "X" (just state it)

### C3: Wordy constructions

Tighten verbose phrases. Academic writing should be precise, not padded.

**Common patterns to shorten:**

| Verbose | Concise |
|---------|---------|
| facilitates the identification of | helps identify |
| has created new opportunities to analyze | has enabled the analysis of |
| at finer administrative levels beyond the state level | below the state level |
| providing visual insights into economic convergence processes | [delete if redundant with preceding clause] |
| the technical barriers to producing publication-quality research outputs that adhere to open-access and reproducibility standards | the technical barriers to producing reproducible, publication-quality research |
| contribute to the open science movement and encourage other researchers to build upon our work by ensuring transparency and verifiability | promote transparency and enable other researchers to build upon our work |
| offering a particularly advantageous platform for | and provides an accessible platform for |

**How to check:** Read each paragraph looking for phrases that can be expressed in fewer words without losing meaning.

### C4: Tense consistency

Each section should use a consistent tense:

| Section | Expected tense |
|---------|---------------|
| Introduction (paper's contributions) | Present ("This paper confirms...") |
| Literature review | Present or past, but consistent within each paragraph |
| Methods | Present ("We employ...") |
| Results | Present ("The results indicate...") |
| Discussion | Present for general statements; past for completed analyses ("Our analysis relied on...") |
| Conclusions | Present for main claims; past for what was done ("We developed...", "Estimates indicate...") |

**How to check:** Read each section and flag tense shifts within paragraphs. Pay special attention to the concluding remarks, where tense mixing is most common.

### C5: Hedging and claim strength

Academic economics writing should be appropriately cautious. Flag overly strong language and replace with hedged alternatives.

**Flag these words/phrases:**

| Too strong | Preferred alternative |
|-----------|----------------------|
| demonstrates that | suggests that, indicates that, is consistent with |
| proves that | provides evidence that |
| clearly shows | shows, suggests |
| powerful | effective, useful |
| robust (unless about statistical robustness) | stable, consistent |
| comprehensive | detailed, extensive |
| groundbreaking | [remove or rephrase] |
| novel | [use sparingly; prefer describing what is new specifically] |
| remarkable/remarkably | notable/notably |
| dramatic/dramatically | pronounced, marked |
| fundamental | important, central |
| essential (for non-essential things) | useful, valuable, important |
| promises (for future work) | should yield, may yield, could yield |
| readily transferable | potentially transferable |

**Principle:** State what was found and let the reader judge its importance. Do not tell the reader something is "important" or "crucial" — show why it matters through the evidence.

### C6: Terminology consistency

Key terms must be used uniformly throughout. Check for inconsistencies:

| Preferred | Variants to fix |
|-----------|----------------|
| nighttime lights | nightlights, night-time lights, night lights |
| NTL (after first definition) | nightlight data (in running text after abbreviation is defined) |
| subnational | sub-national |
| scatterplot | scatter plot, scatter-plot |
| spatial Durbin model | Spatial Durbin Model (do not capitalize mid-sentence) |
| the data are | the data is (academic convention: "data" is plural) |

**How to check:** Grep for each variant and standardize.

### C7: Redundancy

Flag sentences that:
- Repeat the same idea already stated in the preceding sentence
- End with a trailing clause that restates the first half of the sentence
- Use two near-synonyms where one suffices (e.g., "scarce and limited", "transparent and open")

**How to check:** Read each paragraph and ask: "Does every sentence add new information?" If a sentence could be deleted without losing content, flag it.

## Execution steps

1. **Read** the full manuscript (`index.qmd`)
2. **Scan** for each category using Grep and contextual reading:
   - C1: Count occurrences of each word on the overused list
   - C2: Search for each AI-phrase watchlist item
   - C3-C7: Read section by section
3. **Report** proposed edits in a structured table:

   | # | Category | Line | Current text | Proposed edit | Rationale |
   |---|----------|------|-------------|---------------|-----------|
   | 1 | C1 | 67 | "substantially larger" | "considerably larger" | Variety |
   | ... | ... | ... | ... | ... | ... |

4. **Wait for user approval** before applying any edits
5. **Apply** edits using the Edit tool, working top-to-bottom through the file
6. **Verify** by:
   - Re-reading each edited paragraph for flow
   - Grepping for remaining instances of flagged patterns
   - Reporting a summary of changes made

## Tone guidelines

- Conservative and academically formal at all times
- Hedged claims preferred over strong assertions
- No promotional language about tools or methods
- Consistent voice across all sections (avoid a section sounding different from others)
- Do not add content, restructure sections, or change the argument — only improve the expression
