# Add an exclusion stage to a CONSORT tracker

Evaluates formula-based exclusion rules against the currently-active
patient population and appends two new columns to the tracker's data
frame: a character column (`col`) recording the first-matching exclusion
reason for each patient, and a boolean column (`pass_col`) marking the
survivors. Patients already excluded by a prior stage are automatically
gated out.

## Usage

``` r
hv_consort_exclude(
  tracker,
  label,
  col,
  ...,
  excl_label = "Excluded",
  pass_col = NULL
)
```

## Arguments

- tracker:

  An `hv_consort_tracker` from
  [`hv_consort_start()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort_start.md).

- label:

  Character label for the survivor box after this exclusion (e.g.
  `"Eligible"`, `"Analyzed"`).

- col:

  Column name to store exclusion reasons (character). This column will
  contain a reason string for excluded patients and `NA` for survivors.
  Required – no default.

- ...:

  Two-sided formulas of the form `<condition> ~ "<reason string>"`.
  Conditions are evaluated with data masking against the tracker's data
  frame. The **first** matching formula assigns the reason; subsequent
  formulas are not evaluated for already- excluded patients.

- excl_label:

  Character label for the side-box showing exclusion breakdown. Default
  `"Excluded"`.

- pass_col:

  Column name for the survivor boolean column. Defaults to
  `ct_snakify(label)` (e.g. `"eligible"` when `label = "Eligible"`).

## Value

The updated `hv_consort_tracker` (invisibly – pipe-safe).

## See also

[`hv_consort_start()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort_start.md),
[`hv_consort()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort.md)

## Examples

``` r
cohort <- data.frame(
  mrn  = paste0("P", 1:100),
  age  = sample(15:80, 100, TRUE),
  echo = sample(c(TRUE, FALSE), 100, TRUE, prob = c(0.9, 0.1))
)

tracker <- hv_consort_start(cohort, patient_id = mrn) |>
  hv_consort_exclude(
    label    = "Eligible",
    col      = "excl_screen",
    age < 18 ~ "Age < 18"
  ) |>
  hv_consort_exclude(
    label  = "Analyzed",
    col    = "excl_eligible",
    !echo  ~ "Missing echocardiogram"
  )
```
