* `plot.hv_mirror_hist()` gains `split_tall` (default `FALSE`) and
  `split_mult` (default 1.5). When one arm piles into a single bin, say 648 of
  685 patients at a score of 95 to 100%, that bar flattens the figure and the
  small arm and the matched bars cannot be read. With `split_tall = TRUE` the
  y-axis is sized to `split_mult` times the tallest matched (or weighted) bar
  or tallest bar of the smaller arm. Any taller "all patients" bar is cut by a
  white gap, set above the tallest matched bar, and labeled with its full
  count. The limits are set in `coord_cartesian()`, which clips the bar; the
  scale limits used otherwise would drop it.
* The mirrored histogram's fill legend reads "SAVR, all", "SAVR, matched"
  (or "weighted"), and so on, from `group_labels`, in place of the internal
  keys `before_g0`, `matched_g1`. `hv_mirror_hist()` stores the labels in
  `meta$fill_labels` for a `scale_fill_manual(labels = )` that replaces the
  default fill scale.
