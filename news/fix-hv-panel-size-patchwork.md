* `hv_panel_size()` refuses a patchwork. Its panels sit in nested tables, so it
  was sized as a single 6 by 4 panel without a word; it now stops and says to
  size it by hand or draw the panels as facets.
* `hv_panel_size()`'s page is 6.5 inches wide by default, a journal's text
  width, and a panel may shrink to 1.6 inches: on a 6 inch page at 12 pt, three
  facet columns came out about 1.66 inches each and were refused. Three columns
  now fit; four still do not. A single panel is still 6 by 4 inches.
