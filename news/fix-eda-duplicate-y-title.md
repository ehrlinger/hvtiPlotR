* Pages from `plot.hv_eda_pages()` no longer crowd their panels' y axes.
  On a percent or count page the panels in a row share one y axis, drawn on
  the leftmost panel, with one "Proportion" or "Count" title for the page.
  Requires patchwork 1.2.0, which added axis collection.

* A continuous panel from `plot.hv_eda()` no longer repeats its label as the
  y-axis title. The label stays as the panel title, and the axis takes a short
  form of it: the label's trailing parenthesised units, `min` from
  `"Interval:Total Myocardial Ischemia (min)"`, or else the column name. On a
  page of small panels the rotated label ran past its panel into the next.
