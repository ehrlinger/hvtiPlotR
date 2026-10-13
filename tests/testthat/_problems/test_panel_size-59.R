# Extracted from test_panel_size.R:59

# prequel ----------------------------------------------------------------------
library(testthat)
library(ggplot2)
p0 <- ggplot(mtcars, aes(hp, mpg)) + geom_point()

# test -------------------------------------------------------------------------
wide_gutters <- p0 + facet_wrap(~cyl) + theme(panel.spacing = grid::unit(0.5, "in"))
expect_error(hv_panel_size(wide_gutters), "facet_wrap_paginate")
