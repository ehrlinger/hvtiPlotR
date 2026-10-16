* `theme_hv_ppt_dark()` and `theme_hv_ppt_light()` now size facet titles
  (`strip.text`) at `base_size * 0.75`, 24 pt at the default 32, up from
  `base_size / 2` (16 pt), which read as too small on slides. Chain
  `+ theme(strip.text = element_text(size = 16))` for the old size.
