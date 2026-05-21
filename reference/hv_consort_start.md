# Initialise a CONSORT patient-flow tracker

Creates an `hv_consort_tracker` object with one row per patient and a
boolean column indicating that every patient is in the initial
(screened) population. Build the tracker incrementally with
[`hv_consort_exclude()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort_exclude.md),
then convert to a diagram with
[`hv_consort()`](https://ehrlinger.github.io/hvtiPlotR/reference/hv_consort.md).

## Usage

``` r
hv_consort_start(data, patient_id, label = "Screened", pass_col = NULL)
```

## Arguments

- data:

  A data frame – one row per patient.

- patient_id:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Unquoted name of the unique patient identifier column.

- label:

  Character label for the initial population box. Default `"Screened"`.

- pass_col:

  Column name for the initial boolean column. Defaults to
  `ct_snakify(label)` (e.g. `"screened"` when `label = "Screened"`).

## Value

An `hv_consort_tracker` object – a list with:

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
tracker <- hv_consort_start(cohort, patient_id = mrn)
print(tracker)
#> <hv_consort_tracker>
#>   Patients   : 100
#>   ID column  : mrn
#>   Stages     : 1
#>     [screened] Screened -- N = 100
```
