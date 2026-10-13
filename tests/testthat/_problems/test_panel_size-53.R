# Extracted from test_panel_size.R:53

# prequel ----------------------------------------------------------------------
library(testthat)
library(ggplot2)
p0 <- ggplot(mtcars, aes(hp, mpg)) + geom_point()

# test -------------------------------------------------------------------------
wide <- p0 + facet_grid(~carb)
expect_error(hv_panel_size(wide), "facet_wrap_paginate")
