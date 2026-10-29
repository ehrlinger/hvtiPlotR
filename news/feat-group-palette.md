* New `hv_group_palette(levels)`: the house colors for the groups compared in
  an outcome figure, named by group. One group is black; two to five take Paul
  Tol's vibrant palette led by red `#CC3311` and blue `#0077BB`, then teal,
  magenta and cyan; six or seven switch to the muted overflow; more is an error
  of class `hv_group_palette_capacity`. Red and blue now mean the event and
  censored only in figures that draw those roles (`hv_role_palette()`); in an
  outcome curve they are the two groups that stay most distinct for a
  colorblind reader.
