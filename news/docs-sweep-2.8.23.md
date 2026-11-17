* Documentation uses the renamed arguments throughout. The `hv_hazard()` and `hazard_plot()` column arguments refer to `data`, not `curve_data`; `hv_eda_pages()` describes `var_cols`; the vignettes name `axis_cols`, `var_cols`, `event_cols`, `event_time_cols` and `save_ppt()`'s `file`; and the `hv_fit_location()` example no longer passes `hv_panel_box()` its deprecated `mode`.

* The SAS migration guide's alluvial example names its `axis_cols`, and its UpSet example no longer passes `sample_upset_data()` an argument it does not have, so both run as written.

* The `save_ppt()` argument table in the decorators vignette lists `panel_box`, `fit` and `align` in place of the `width`, `height`, `left` and `top` arguments it no longer has, and the README and that vignette list `theme_hv_ppt_slate()` among the themes.
