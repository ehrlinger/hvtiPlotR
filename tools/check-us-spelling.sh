#!/usr/bin/env bash
# Fail when a British spelling appears in the package's prose or code.
#
# hvtiPlotR is written in US spelling: "color", "gray", "analyzed". This scans
# the files git sees (tracked, or untracked and not ignored) under R/, tests/,
# vignettes/, man/, inst/, README* and NEWS.md, and exits 1 listing every line
# that still carries a British form.
#
# Run from anywhere:  bash tools/check-us-spelling.sh
#
# A line is reported only after the allowlist below has been stripped from it.
# The allowlist is for tokens that cannot change without changing behavior
# for a caller, not for prose that is merely awkward to fix. Keep it short and
# say why each entry is there.

cd "$(dirname "$0")/.." || exit 2

stems='organ|summar|optim|recogn|normal|standard|visual|initial|priorit|minim|maxim'
stems="$stems|character|parameter|categor|custom|emphas|real|util|final|serial|random"

words='\b(re)?colour(s|ed|ing|ful|less|blind)?\b'
words="$words|scale_colour_[[:alnum:]_*]+|theme_grey"
words="$words|\bgrey(s|ed|ish|scale|[0-9]+)?\b"
words="$words|\bbehaviour(s|al|ally)?\b|\b(dis)?favour(s|ed|ing|able|ite|ites)?\b"
words="$words|\bhonour(s|ed|ing|able)?\b|\blabour(s|ed|ing)?\b|\bneighbour(s|ing|hood)?\b"
words="$words|\banalys(e|ed|ing)\b"
words="$words|\b(re|un|de)?($stems)is(e|es|ed|ing|ation|ations|er|ers)\b"
words="$words|\bcentre(s|d)?\b|\bcentring\b|\bmetre(s)?\b|\blicence(s)?\b"
words="$words|\bcatalogue(s|d)?\b|\bartefact(s)?\b|\bmodell(ing|ed|er|ers)\b"
words="$words|\b(re|un)?labell(ed|ing)\b|\btravell(ed|ing|er|ers)\b"
words="$words|\bfulfil(s|ment)?\b|\benrol(s|ment|ments)?\b|\bjudgement(s)?\b"
words="$words|\bprogramme(s)?\b|\bwhilst\b|\bamongst\b"

hits=$(git ls-files -z --cached --others --exclude-standard -- R tests vignettes man inst 'README*' NEWS.md |
  xargs -0 grep -nIiE "$words" /dev/null)

# Allowlist, applied to "path:line:text" before the words are matched again.
remaining=$(printf '%s\n' "$hits" | WORDS="$words" perl -ne '
  my ($path) = /^([^:]+):/;
  # scale_colour_hv() is kept as an exported alias of scale_color_hv(), as
  # ggplot2 keeps its own scale_colour_*() beside scale_color_*().
  s/\bscale_colour_hv\b//g;
  # ggplot2 stores the aesthetic as "colour" whatever the caller typed: the
  # key a scale is built on, the column in ggplot_build() data, and the field
  # of a theme element or mapping.
  s/"colour"//g;
  s/\$colour\b//g;
  # make_footnote(colour =) and hv_ppt_series(colours =) are aliases of
  # color and colors, kept so existing calls work. Only the files that define,
  # document or test them may name them, and only as an argument. The other
  # three aliases (colour_col, line_colour, node_colours) are snake_case, which
  # the word boundary above never matches.
  if ($path =~ m{^(R/pdf_footnote\.R|R/ppt-series\.R|man/make_footnote\.Rd|man/hv_ppt_series\.Rd|tests/testthat/test_ppt_series\.R|tests/testthat/test_argument_spellings\.R)$}) {
    s/"colours?"|`colours?`|\\item\{colours?\}|\@param colours?\b//g;
    s/\bcolours?\b(?=\s*(=|<-|\)|,|\]|$))//g;
  }
  # NEWS.md is a record: a released entry names the identifiers of its day.
  s/`[^`]*`//g if $path eq "NEWS.md";
  print if /$ENV{WORDS}/i;
')

if [ -n "$remaining" ]; then
  echo "British spellings found; use US spelling (see tools/check-us-spelling.sh):" >&2
  printf '%s\n' "$remaining" >&2
  exit 1
fi
echo "US spelling check passed."
