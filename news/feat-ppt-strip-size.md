* `theme_hv_ppt_dark()` and `theme_hv_ppt_light()` now size facet titles
  (`strip.text`) at `base_size * 0.75`, 24 pt at the default 32, up from
  `base_size / 2` (16 pt), which read as too small on slides. Chain
  `+ theme(strip.text = element_text(size = 16))` for the old size.

* `hv_panel_box()` now returns the same rectangle for the dark and light
  templates, `list(width = 8.79, height = 3.9, left = 2.67, top = 1.6)`, so
  `save_ppt()` places dark-template figures 0.31 in lower and 0.52 in shorter
  than before. Both templates share one title placeholder (to 1.33 in), and
  the old dark rectangle started at 1.29 in, inside it: the larger facet
  titles touched the slide title. Pass
  `panel_box = list(width = 8.79, height = 4.422, left = 2.67, top = 1.29)`
  to rebuild an old dark deck at its old geometry.
