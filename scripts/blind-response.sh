#!/usr/bin/env bash
# blind-response.sh — build a reviewer-blind copy of the response-to-referees report.
#
# Why this exists:
#   Response1.tex is the non-blind master. It quotes the manuscript verbatim, and two of
#   those quoted passages carry the project's repository URLs, which name the lab and the
#   GitHub account. The manuscript uploaded for review is blinded, so a non-blind response
#   document sitting beside it would defeat the blinding entirely.
#
#   Response1.tex is deliberately NOT edited. It stays the master so that
#   audit-scratch/verify/check_quotes.py can keep comparing its quotes against the real
#   index.qmd. The redactions below are applied to a copy at build time, exactly the way
#   scripts/clean-render.sh blinds the manuscript.
#
#   The replacement wording matches the blind manuscript sentence for sentence, so a
#   referee comparing the response against the PDF in front of them sees the same text.
#
# Output: docs/response-report1/Response1-blind.pdf
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="docs/response-report1/Response1.tex"
WORK="docs/response-report1/Response1-blind.tex"

[ -f "$SRC" ] || { echo "ERROR: $SRC not found" >&2; exit 1; }

python3 - "$SRC" "$WORK" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src).read()
n = 0

def rep(old, new):
    global s, n
    c = s.count(old)
    if c != 1:
        sys.exit("expected exactly 1 occurrence, found %d: %r" % (c, old[:70]))
    s = s.replace(old, new)
    n += 1

# Quoted introduction passage (response to comment [1.9]).
rep("""The notebooks, the data, and the manuscript source are in the project
repository at <https://github.com/quarcs-lab/project2025s-py>, and their rendered
versions are embedded in the online edition at
<https://quarcs-lab.github.io/project2025s-py/>.''}""",
    """The notebooks, the data, and the manuscript source are in the project
repository, and their rendered versions are embedded in the online edition; both URLs
are omitted for blind review.''}""")

# Quoted data-and-code-availability statement (response to comment [2.19]).
rep("""All data and computational code used in this study are available in the project
repository at <https://github.com/quarcs-lab/project2025s-py>. The interactive HTML
version of this manuscript (<https://quarcs-lab.github.io/project2025s-py/>) embeds the
computational notebooks, allowing readers to inspect the complete analytical pipeline
from raw data to published results.""",
    """All data and computational code used in this study are available in the project
repository: [Repository URL removed for blind review]. An interactive HTML
version of this manuscript embeds the
computational notebooks, allowing readers to inspect the complete analytical pipeline
from raw data to published results.""")

open(dst, "w").write(s)
print("applied %d redactions" % n)
PY

cd docs/response-report1
latexmk -pdf -interaction=nonstopmode -halt-on-error Response1-blind.tex >/dev/null 2>&1 || {
  echo "ERROR: Response1-blind.tex failed to compile" >&2; exit 1; }
latexmk -c Response1-blind.tex >/dev/null 2>&1 || true
cd ../..

# Verify: no identifying string may survive. Third-person self-citations are permitted.
LEAK=$(grep -Eic "quarcs-lab|github\.com/|bit\.ly/|KAKENHI|24K04884|carlosmendez|@gmail" \
       "$WORK" || true)
if [ "$LEAK" != "0" ]; then
  echo "ERROR: $LEAK identifying string(s) survived in $WORK" >&2
  grep -Ein "quarcs-lab|github\.com/|bit\.ly/|KAKENHI|24K04884|carlosmendez|@gmail" "$WORK" >&2
  exit 1
fi

echo "OK  docs/response-report1/Response1-blind.pdf ($(pdfinfo docs/response-report1/Response1-blind.pdf | awk '/^Pages/{print $2}') pages, 0 identifying strings)"
