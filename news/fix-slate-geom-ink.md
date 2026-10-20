* `theme_hv_ppt_slate()` now draws geoms that have no color of their own in
  black on its white panel. It inherited the dark theme's white ink, so under
  ggplot2 4.0 an uncolored `geom_line()`, `geom_point()` or `geom_hline()`
  drew white on white and vanished. Text outside the panel stays white.
  Decks that worked around this with
  `+ theme(geom = element_geom(ink = "black", paper = "white"))` keep working.
