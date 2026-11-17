* `hv_followup_panels()` can read the origin year from the data. Name the operation date in the new
  `opdate_col` and leave `origin_year` `NULL`: each patient's date less their `opyrs_col` lands on the
  origin the build counted from. Given both, a disagreement stops, since a wrong origin slides every
  point along the x-axis and shows no other symptom; this is the "first operation in 1992" report on a
  2014 to 2026 cohort. `meta$origin_source` says which it was.
