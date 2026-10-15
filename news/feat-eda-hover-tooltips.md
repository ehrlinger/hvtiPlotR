* `plot.hv_eda()` and `plot.hv_eda_pages()` gain `interactive`, which gives the
  bars of a percent or count panel hover labels: each bar's tooltip names its
  category, its `x` bin, and its count and percent of the bin. The default,
  `NULL`, turns them on in knitr HTML output when ggiraph is installed. Printed
  or saved, a plot is the same as before. The new `hv_girafe()` renders a plot
  or page as an HTML widget without embedding font files, which kept an 8-panel
  page at 0.4 MB rather than 8.6 MB. ggiraph and gdtools join Suggests.
