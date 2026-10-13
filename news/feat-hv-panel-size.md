* New `hv_panel_size()` chooses figure dimensions from a plot's facet layout. A
  single panel gets the CORR standard 6 by 4 inch figure; a faceted plot gets
  3 by 2 inch panels plus the axes, strips, titles and legend around them,
  measured by `hv_ggsave_dims()`. Panels shrink together, keeping their 3:2
  shape, to fit a 6 by 9 inch page, and below 1.75 inches wide the function
  stops and points to `ggforce::facet_wrap_paginate()`.
