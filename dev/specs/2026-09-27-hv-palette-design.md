# Design: `hv_palette()` and `scale_colour_hv()` / `scale_fill_hv()`

**Date:** 2026-09-27
**Status:** Proposed, for John Ehrlinger's review. §7 lists what he decides.
**Repo:** hvtiPlotR, release 2.7.18. The templates adopt it in hvtiRtemplates 1.2.3
(release plan phase 3b, `dev/specs/2026-09-25-release-eda-complete-plan.md` there).

## 1. Motivation

The 2026-09-24 template review with Lauren settled one colour rule for the EDA
reports: **an event is red, censored is blue, missing is light grey; every other
level takes ColorBrewer Set1, then Set3 when the levels outrun it; points at alpha
0.5; a plot with one level draws blue.** The release plan adds a precedence rule so
that a plot with one level is not ambiguous. A level named as the event, censored
or missing keeps its colour even when it is the only level. The single-level blue
applies only to a sole level with no role, which Set1 would otherwise draw red.

Today the rule is written out by hand, three different ways:

| where | what it does |
|---|---|
| `dp-gfup` (and `dp-eda`'s follow-up section) | `COLOURS <- c(alive = "#377EB8", dead = "#E41A1C", event = "#4DAF4A")`, hex codes pasted into the template |
| `dp-postage` (and `dp-eda`'s pages) | ggplot's default hue palette; the rule is not applied at all |
| examples here (`eda-plots.R`, `goodness-followup.R`, `followup-panels.R`) | `"steelblue"`/`"firebrick"`, `"blue"`/`"red"`, `"#377EB8"`/`"#E41A1C"` and `"grey80"`, each chosen by hand |

CONTRIBUTING keeps colours the caller's choice, and this design keeps it that way.
The helper is an **opt-in scale**, never a default inside a constructor or a
`plot()` method. What it removes is the copy of the rule in every caller.

## 2. API

```r
hv_palette(levels, event = NULL, censored = NULL, missing = "(Missing)")

scale_colour_hv(event = NULL, censored = NULL, missing = "(Missing)", ...)
scale_fill_hv(event = NULL, censored = NULL, missing = "(Missing)", ...)
```

- `hv_palette()` returns a character vector of hex colours **named by `levels`**,
  in `levels` order. This is the rule itself, and it is testable without a plot.
- `event`, `censored`: level names, or `NULL` for none. Each may name more than
  one level, and all of them take the role's colour. A name that is not among
  `levels` is ignored, so one call can serve every panel on a page (see §4).
- `missing`: the level name that stands for missing values, `"(Missing)"` by
  default because that is the explicit level `hv_eda()` adds. `NA` values
  themselves take the same grey through the scale's `na.value`.
- `scale_*_hv()` return a discrete ggplot2 scale. `...` passes to
  `ggplot2::discrete_scale()` (`name`, `labels`, `guide` and so on).

## 3. The rule, precisely

Given `levels`:

1. **Roles first.** A level named in `event` is red, `#E41A1C` (Set1's red). A
   level named in `censored` is blue, `#377EB8` (Set1's blue). A level named in
   `missing` is light grey, `grey80` (`#CCCCCC`), the value the examples here
   already use. If a name appears in more than one role, that is an error
   naming the level.
2. **A sole level with no role is blue.** The review decided this for the one
   case where Set1 would draw it red and suggest an event.
3. **Everything else, in `levels` order, takes the rotation.** The rotation is
   Set1 with its grey `#999999` removed, so grey only ever means missing:
   red, blue, green, purple, orange, yellow, brown, pink. **Red and blue are
   removed as well when the event or censored role is in use.** Otherwise a
   non-event level would take the event's red, and the reader could not tell
   them apart.
4. **Set3 when the rotation runs out.** If the remaining levels outnumber the
   rotation, *all* of them switch to Set3 with its grey `#D9D9D9` removed (11
   colours). Switching wholesale keeps saturated Set1 and pastel Set3 out of the
   same legend.
5. **Beyond that, an error**, naming how many levels there were and how many
   colours exist. This matches `hv_ppt_palette()`, which errors rather than
   recycling, because two levels sharing a colour is worse than a stopped
   script.

**Check against today's figure.** `dp-gfup`'s event panel has the levels
`No event`, the event's title, and `Death`. With `censored = "No event"` and
`event = "Death"`, step 1 draws Death red and No event blue. Step 3 then starts
the rotation at green, because red and blue are in use, so the non-fatal event
is `#4DAF4A`. That is exactly the three colours `COLOURS` hard-codes today, so
adopting the helper leaves the follow-up figures unchanged.

The Set1 and Set3 hex values are written into the source, as `hv_ppt_palette()`
writes its own, so the package takes no dependency on RColorBrewer. A test
compares them with `scales::brewer_pal()` when scales is installed (it is in
Suggests), so a transcription error cannot slip through.

## 4. The scale works per panel

`dp-postage` finishes a page with one scale applied to every panel,
`page & scale_fill_hv(...)`, and each panel has its own levels. Picture a page
with `female` (0, 1) and `nyha` (I–IV). A fixed named vector, which is what
`scale_fill_manual()` needs, cannot express "Set1 in each panel's own order".

It does not have to. In ggplot2 (4.0.3 installed; the floor is 3.5.0), a
discrete scale's `map(self, x, limits)` receives the panel's limits, while
`palette(n)` receives only a count. So `scale_*_hv()` return a `ggproto` subclass
of `ggplot2::ScaleDiscrete` whose `map` computes `hv_palette(limits, ...)` and
matches `x` to it by name. ggplot clones a scale for each plot it builds, so each
panel gets its own colours from its own levels, and the rule holds panel by
panel, including the single-level blue.

**The cost** is reliance on `map`'s signature, which is ggplot2's extension
surface rather than documented API. It is the same in 3.5.0 and 4.0.3. A test
builds a two-panel patchwork with different levels and checks every point's
colour, so a ggplot2 change that broke it would fail here before it reached a
template. The alternative, a named vector over the union of every panel's
levels, gives a level the same colour on every panel. It cannot keep the
single-level blue, and it would give panel two whatever Set1 colours panel one
left over. §7 asks which John wants.

## 5. Points and alpha

The review's alpha 0.5 is a layer setting, not a colour, so a scale cannot carry
it. It stays where it is, in the templates' `ALPHA` edit point. The scales take no
`alpha` argument.

## 6. Relationship to `hv_ppt_palette()`

The two do different jobs and both stay. `hv_ppt_palette()` gives **series**
colours for slides: Okabe-Ito, ordered for contrast against a dark or light
background, with no meaning attached to any position. `hv_palette()` gives
**semantic** colours for the EDA and follow-up figures, where red *means* event.
Each help page names the other under `@seealso`, so nobody reaches for the wrong
one. They are not merged: a slide series has no event, and an EDA panel has no
dark mode.

## 7. For John to decide

1. **Per-panel colours (§4, recommended) or one colour per level name across the
   page?** Per panel follows the review's rule literally. Per name means `1` is
   the same colour wherever it appears, but it gives up the single-level blue.
2. **Colourblind safety.** Set1's red against green is the most common
   colour-vision confusion, and `hv_ppt_palette()` chose Okabe-Ito for that
   reason. The review chose Set1 because it matches the SAS output readers
   already know, and this design keeps that choice. Say whether any figure type
   should default to Okabe-Ito instead. Set1's yellow `#FFFF33` is also faint on
   white. Dropping it from the rotation is a one-line change if wanted.
3. **The name.** `hv_palette()` sits next to `hv_ppt_palette()`, and a reader could
   take it for the general palette. `hv_role_palette()` says what makes it
   different. The release plan's working name is kept here until John picks.

## 8. Testing strategy

- `hv_palette()`: every rule in §3 by example. Event and censored take red and
  blue wherever they sit in `levels`. Missing takes grey. The rotation skips red
  and blue only when a role uses them. A sole level with no role is blue. A sole
  event level is red, a sole censored level blue, a sole missing level grey. Set3
  replaces Set1 wholesale at the right count. Too many levels, and a level named
  in two roles, each give an error. The `dp-gfup` levels reproduce `COLOURS`
  exactly.
- The hex values against `scales::brewer_pal()`, skipped if scales is absent.
- `scale_fill_hv()` on a two-panel patchwork (`&`) with different levels: each
  panel's built colours per §3, via `ggplot_build()`, not merely a ggplot class.
  Prove it by mutation: have `map` ignore `limits`, and watch it fail.
- `scale_colour_hv()` on a point layer, with a real `NA` taking grey.

## 9. Package integration

- New file `R/palette-hv.R`. Three exports, each with `@return`, runnable
  examples, and an entry in `_pkgdown.yml` (the index here is explicit).
- `vignettes/plot-functions.qmd` gets a worked example, and the SAS migration
  guide a row mapping the SAS colour conventions to `scale_fill_hv()`
  (CONTRIBUTING steps 6 and 7).
- Examples that hand-pick event and censored colours (`eda-plots.R`,
  `goodness-followup.R`, `followup-panels.R`) may switch to the helper in the
  same release. They are examples only, so no behaviour changes.
- NEWS under unreleased; the bump to 2.7.18 is its own PR after merge.

## 10. Out of scope

- Applying any of this by default inside a constructor or `plot()` method, which
  CONTRIBUTING forbids.
- A continuous or diverging scale. The rule is for discrete levels only.
- The templates' adoption, which is hvtiRtemplates phase 3b.
