* `hv_panel_size()` and `hv_ggsave_dims()` no longer leave a graphics device
  open. `ggplotGrob()` opens R's default device when none is open, and both
  called it before opening their own null device, so each call outside a
  plotting session left a `pdf` device behind; with a device already open, it
  stays the current one.
