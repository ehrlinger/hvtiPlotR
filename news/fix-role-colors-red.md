* The role colors are now Paul Tol's vibrant red `#CC3311` for an event and
  blue `#0077BB` for censored, replacing Okabe-Ito vermilion `#D55E00` and
  blue `#0072B2`. Readers asked for a red that reads as red. Beside the
  rotation's bluish green the colorblind margin narrows a little (smallest CIELAB
  distance 47 deuteranopic and 34 protanopic, against 53 and 37), and stays well
  clear of the red-green pairs that fail. When a role is
  present the rotation still drops its own blue and vermilion, so no other level
  is mistaken for the event or for censored. `hv_palette()` and
  `hv_ppt_palette()` are unchanged.
