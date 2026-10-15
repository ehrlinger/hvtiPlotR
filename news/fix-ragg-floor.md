* `ragg` is floored at 1.2.1. Earlier versions crash R when writing a TIFF
  with a transparent background, which `save_manuscript()` now writes by
  default for an extension-less path.
