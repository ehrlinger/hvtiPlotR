# Initialize a CONSORT patient-flow tracker

Creates an `hv_consort_tracker` object with one row per patient and a
boolean column indicating that every patient is in the initial
(screened) population. Build the tracker incrementally with
[`hv_consort_exclude()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort_exclude.md),
then convert to a diagram with
[`hv_consort()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort.md).

## Usage

``` r
hv_consort_start(
  data,
  patient_id_col,
  label = "Screened",
  pass_col = NULL,
  patient_id
)
```

## Arguments

- data:

  A data frame, one row per patient.

- patient_id_col:

  Name of the unique patient identifier column, as a string. Its values
  must be unique and not missing; a repeated or missing ID is an error.

- label:

  Character label for the initial population box. Default `"Screened"`.

- pass_col:

  Column name for the initial boolean column. Defaults to
  `ct_snakify(label)` (e.g. `"screened"` when `label = "Screened"`).

- patient_id:

  Deprecated: the identifier column unquoted. It works, with a
  once-per-session warning, until hvtiPlotR 2.9.0; so does an unquoted
  name passed by position.

## Value

An `hv_consort_tracker` object, a list with:

- `$data`:

  Patient-level data frame with boolean/character columns appended per
  stage.

- `$stages`:

  Ordered list of stage descriptors (`label`, `include_col`, `excl_col`,
  `excl_label`).

- `$patient_id_col`:

  Column name of the patient identifier.

## See also

[`hv_consort_exclude()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort_exclude.md),
[`hv_consort()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort.md)

## Examples

``` r
cohort  <- data.frame(mrn = paste0("P", 1:100), age = sample(15:80, 100, TRUE))
tracker <- hv_consort_start(cohort, patient_id_col = "mrn")
print(tracker)
#> <hv_consort_tracker>
#>   Patients   : 100
#>   ID column  : mrn
#>   Stages     : 1
#>     [screened] Screened -- N = 100
```
