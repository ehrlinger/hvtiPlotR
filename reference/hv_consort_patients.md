# Retrieve patient IDs at a CONSORT stage

Returns the IDs of patients who are active at a given stage (or who were
excluded for a specific reason at a given stage).

## Usage

``` r
hv_consort_patients(tracker, stage, reason = NULL)
```

## Arguments

- tracker:

  An `hv_consort_tracker`.

- stage:

  Character – either the `include_col` name (e.g. `"eligible"`) or the
  stage label (case-insensitive, e.g. `"Eligible"`).

- reason:

  Optional character. If supplied, returns patients excluded from *this*
  stage for the specified reason (the string must exactly match a value
  in the exclusion column). The `stage` arg then refers to the stage
  *before* the exclusion (e.g. `"screened"` for `excl_screen`).

## Value

A character vector of patient IDs (from the column named in
`tracker$patient_id_col`).

## Examples

``` r
tracker <- hv_consort_start(data.frame(id = 1:10, age = c(rep(15,3), rep(30,7))),
                             patient_id = id) |>
  hv_consort_exclude(label = "Eligible", col = "excl_screen",
                      age < 18 ~ "Age < 18")
hv_consort_patients(tracker, "eligible")
#> [1] "4"  "5"  "6"  "7"  "8"  "9"  "10"
hv_consort_patients(tracker, "screened", reason = "Age < 18")
#> [1] "1" "2" "3"
```
