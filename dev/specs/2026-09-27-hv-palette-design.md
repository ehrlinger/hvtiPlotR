# Design: `hv_role_palette()` and `scale_colour_hv()` / `scale_fill_hv()`

**Date:** 2026-09-27
**Status:** Proposed, revised the same day with John Ehrlinger's decisions (§7).
One question remains open for him, §7.4.
**Repo:** hvtiPlotR, release 2.7.18. The templates adopt it in hvtiRtemplates 1.2.3
(release plan phase 3b, `dev/specs/2026-09-25-release-eda-complete-plan.md` there).

## 1. Motivation

The 2026-09-24 template review with Lauren settled one colour rule for the EDA
reports: an event is red, censored is blue, missing is light grey; every other
level takes a qualitative palette in order; points at alpha 0.5; a plot with one
level draws blue. The review named ColorBrewer Set1, then Set3. **John replaced
that with a colourblind-safe set on 2026-09-27** (§7), and this design follows
that decision. The roles and the precedence stay as the review set them. The
release plan adds a precedence rule so that a plot with one level is not
ambiguous. A level named as the event, censored or missing keeps its colour even
when it is the only level. The single-level blue applies only to a sole level with
no role.

Today the rule is written out by hand, three different ways:

| where | what it does |
|---|---|
| `dp-gfup` (and `dp-eda`'s follow-up section) | `COLOURS <- c(alive = "#377EB8", dead = "#E41A1C", event = "#4DAF4A")`, Set1 hex codes pasted into the template |
| `dp-postage` (and `dp-eda`'s pages) | ggplot's default hue palette; the rule is not applied at all |
| examples here (`eda-plots.R`, `goodness-followup.R`, `followup-panels.R`) | `"steelblue"`/`"firebrick"`, `"blue"`/`"red"`, `"#377EB8"`/`"#E41A1C"` and `"grey80"`, each chosen by hand |

CONTRIBUTING keeps colours the caller's choice, and this design keeps it that way.
The helper is an **opt-in scale**, never a default inside a constructor or a
`plot()` method. What it removes is the copy of the rule in every caller.

## 2. API

```r
hv_role_palette(levels, event = NULL, censored = NULL, missing = "(Missing)")

scale_colour_hv(event = NULL, censored = NULL, missing = "(Missing)",
                na.value = "#CCCCCC", ...)
scale_fill_hv(event = NULL, censored = NULL, missing = "(Missing)",
              na.value = "#CCCCCC", ...)
```

- `hv_role_palette()` returns a character vector of hex colours **named by
  `levels`**, in `levels` order. This is the rule itself, and it is testable
  without a plot.
- `event`, `censored`: level names, or `NULL` for none. Each may name more than
  one level, and all of them take the role's colour. **A role name that is not
  among `levels` has no effect at all**: it takes no colour and changes nothing
  in the rotation (§3, step 3). That is what lets one call serve every panel on
  a page (§4).
- `missing`: the level name that stands for missing values, `"(Missing)"` by
  default because that is the explicit level `hv_eda()` adds.
- `na.value`: the colour for a real `NA`, `#CCCCCC` by default, the same grey as
  the missing level. `ggplot2::discrete_scale()` defaults `na.value` to `NA`,
  which leaves missing observations unmapped, so the scales must set it rather
  than forward it. A caller may still override it.
- `scale_*_hv()` return a discrete ggplot2 scale. `...` passes to
  `ggplot2::discrete_scale()` (`name`, `labels`, `guide` and so on).

The scales keep the short `_hv` suffix: `scale_fill_hv()` reads as the house
scale at the point of use, and the palette function's name carries the
distinction from `hv_ppt_palette()`.

## 3. The rule, precisely

Everything is decided from **one panel's levels**. For the page scale, those are
the panel's limits (§4).

1. **Roles first.** A level named in `event` is vermillion, `#D55E00`, the
   Okabe-Ito red. A level named in `censored` is blue, `#0072B2`. A level named
   in `missing` is light grey, `#CCCCCC` (`grey80`), the value the examples here
   already use. A name in more than one role is an error naming the level.
2. **The rotation is `hv_ppt_palette("light")`**, the package's existing
   colourblind-safe series for white backgrounds: blue `#0072B2`, vermillion
   `#D55E00`, green `#009E73`, reddish purple `#CC79A7`, orange `#E69F00`,
   black `#000000`. It is Okabe-Ito without its yellow and sky blue. Using it
   keeps one definition of the series colours in the package rather than two.
3. **Role colours leave the rotation only when a role is present in this
   panel.** If any of the panel's levels is named in `event` or `censored`, both
   blue and vermillion leave the rotation, so no other level can be mistaken for
   the event or for censored. Both go even when only one role is present,
   because a non-event level in vermillion reads as an event. If neither role is
   among the panel's levels, the full rotation applies. That is §2's "no effect
   at all", and a test covers exactly this case: one page scale over a panel
   with the event level and a panel without it.
4. **Every other level, in `levels` order, takes the rotation.** Because the
   rotation starts at blue, a sole level with no role is drawn blue without a
   special case. The review's single-level rule falls out of the order.
5. **Past the rotation, Tol muted, wholesale.** If the remaining levels outnumber
   the rotation, *all* of them switch to Paul Tol's muted palette, which is also
   designed to be colourblind safe, less sand `#DDCC77` and cyan `#88CCEE`. That
   leaves rose `#CC6677`, indigo `#332288`, green `#117733`, wine `#882255`,
   teal `#44AA99`, olive `#999933` and purple `#AA4499`. When a role is present
   in the panel, rose leaves too, because it reads as the event. Switching
   wholesale keeps two palettes out of one legend.
6. **Beyond that, see §7.4.**

**Every colour clears 2:1 against white, except the missing grey.** That is the
test behind "drop the light yellow for white backgrounds". Measured as WCAG
relative-luminance contrast:

| dropped | contrast | kept, lowest | contrast |
|---|---|---|---|
| Okabe-Ito yellow `#F0E442` | 1.32:1 | Okabe-Ito orange `#E69F00` | 2.25:1 |
| Tol sand `#DDCC77` | 1.62:1 | Tol teal `#44AA99` | 2.82:1 |
| Tol cyan `#88CCEE` | 1.76:1 | Tol olive `#999933` | 3.02:1 |
| Okabe-Ito sky blue `#56B4E9` | 2.31:1 | (not in `hv_ppt_palette("light")`) | |

The missing grey sits at 1.61:1 on purpose: missing is the one level meant to
recede. A test asserts the 2:1 floor over every colour the rule can return, so a
later palette edit cannot bring a faint colour back unnoticed.

**Capacity on white.** Without a role in the panel, the rotation holds 6 levels
and Tol muted 7. With a role, 4 other levels and then 6. No qualitative palette
stays colourblind safe much past seven or eight levels, so the fallback adds
little. That is a property of colour vision, not of this design.

**Today's follow-up figures keep their structure but change colour.**
`dp-gfup`'s event panel has the levels `No event`, the event's title, and
`Death`. With `censored = "No event"` and `event = "Death"`, Death is
vermillion and No event blue. The rotation then starts at green, since blue and
vermillion leave it, so the non-fatal event is green. The pattern is
Set1's (blue, red, green), but in the Okabe-Ito colours: `#0072B2`, `#D55E00`,
`#009E73` replace `#377EB8`, `#E41A1C`, `#4DAF4A`. That is the deliberate
consequence of the colourblind-safe decision, and the templates' NEWS must say so
when 3b lands.

The hex values are written into the source, as `hv_ppt_palette()` writes its own,
so the package takes no new dependency. The Okabe-Ito and Tol muted values above
were checked against khroma's `data-raw/schemes_OkabeIto.R` and
`schemes_PaulTol.R`.

## 4. The scale works per panel

Decided by John on 2026-09-27: **colours are assigned per panel**, not one colour
per level name across the page.

`dp-postage` finishes a page with one scale applied to every panel,
`page & scale_fill_hv(...)`, and each panel has its own levels. Picture a page
with `female` (0, 1) and `nyha` (I–IV). A fixed named vector, which is what
`scale_fill_manual()` needs, cannot express "the rotation in each panel's own
order".

It does not have to. In ggplot2 (4.0.3 installed; the floor is 3.5.0), a
discrete scale's `map(self, x, limits)` receives the panel's limits, while
`palette(n)` receives only a count. So `scale_*_hv()` return a `ggproto` subclass
of `ggplot2::ScaleDiscrete` whose `map` computes
`hv_role_palette(limits, ...)` and matches `x` to it by name. ggplot clones a
scale for each plot it builds, so each panel gets its own colours from its own
levels. Step 3's role check therefore runs panel by panel, which is what a page
with the event in only some panels needs.

**The cost** is reliance on `map`'s signature, which is ggplot2's extension
surface rather than documented API. It is
`map = function(self, x, limits = self$get_limits())` in both 3.5.0 (checked at
the `v3.5.0` tag) and 4.0.3. A test builds a two-panel patchwork with different
levels and checks every point's colour, so a ggplot2 change that broke it would
fail here before it reached a template.

## 5. Points and alpha

The review's alpha 0.5 is a layer setting, not a colour, so a scale cannot carry
it. It stays where it is, in the templates' `ALPHA` edit point. The scales take no
`alpha` argument.

## 6. Relationship to `hv_ppt_palette()`

`hv_role_palette()` now **builds on** `hv_ppt_palette("light")` rather than
standing beside it. `hv_ppt_palette()` gives **series** colours with no meaning
attached to a position. `hv_role_palette()` gives **role** colours, where
vermillion *means* event, and takes its rotation from the series. Each help page
names the other under `@seealso`. If the light series ever changes,
`hv_role_palette()` follows it, and the 2:1 test and the role tests say whether
the change still keeps the rule.

## 7. Decisions

Decided by John Ehrlinger, 2026-09-27:

1. **Name: `hv_role_palette()`.** The scales stay `scale_colour_hv()` and
   `scale_fill_hv()`.
2. **Per panel** (§4).
3. **A colourblind-safe set, with the light yellow dropped for white
   backgrounds.** Okabe-Ito through `hv_ppt_palette("light")`, then Tol muted,
   with the 2:1 floor of §3 as the test. This replaces the review's Set1 and
   Set3, which fail on both counts: Set1's red against green is the commonest
   colour-vision confusion, Set1's yellow is 1.07:1 on white, and Set3's pastels
   mostly fall under 2:1.

Still open:

4. **More levels than the palette holds.** `hv_ppt_palette()` errors rather than
   recycling, because two levels sharing a colour is worse than a stopped script.
   That is right for `hv_role_palette()` called directly. Inside an EDA page,
   though, one categorical with nine levels would stop the whole report.
   Recommended: **`hv_role_palette()` errors, and the scales warn and draw that
   panel in ggplot's default hue palette**, naming the variable and its level
   count, so the report renders and says which panel is not colourblind safe.
   The alternative is to error in both.

## 8. Testing strategy

- `hv_role_palette()`: every rule in §3 by example. Event and censored take
  vermillion and blue wherever they sit in `levels`. Missing takes grey. The
  rotation drops blue and vermillion only when a role is among `levels`, and the
  same call with the role absent gives the full rotation. A sole level with no
  role is blue. A sole event level is vermillion, a sole censored level blue, a
  sole missing level grey. Tol muted replaces the rotation wholesale at the
  right count, with and without a role. A level named in two roles gives an
  error, as does whatever §7.4 decides for too many levels. The `dp-gfup` levels
  give blue, vermillion and green.
- Every colour the rule can return, bar missing, clears 2:1 against white.
- `scale_fill_hv()` on a two-panel patchwork (`&`), one panel holding the event
  level and one not, with different level counts: each panel's built colours
  per §3, via `ggplot_build()`, not merely a ggplot class. Prove it by mutation:
  have `map` ignore `limits`, and watch it fail.
- `scale_colour_hv()` on a point layer with a real `NA`, taking `#CCCCCC`
  through the default `na.value`, and an overridden `na.value` taking effect.

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
- Dark backgrounds. The rule is for white; `hv_ppt_palette("dark")` serves
  slides.
- The templates' adoption, which is hvtiRtemplates phase 3b.
