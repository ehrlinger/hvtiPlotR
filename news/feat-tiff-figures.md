* `save_manuscript()` writes TIFF as well as PNG, and TIFF is the default.
  A new `format` argument, `"tiff"` (default) or `"png"`, supplies the
  extension for a `file` or `draft_file` given without one, unless you pass
  a `device`, in which case `file` is used as given. A TIFF is written by
  ggplot2's `ragg::agg_tiff()` device with LZW compression at `dpi`, the same
  pixel geometry as the PNG, so a 6 x 4 in figure at 300 dpi is 1800 x 1200
  pixels and tens of kilobytes rather than the several megabytes of the
  uncompressed TIFF `ggplot2::ggsave()` writes. An extension you write always
  wins, so a `.png` meant for an HTML report stays a PNG; browsers do not
  display TIFF. `ragg` is now imported.
