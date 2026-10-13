# Extracted from test_panel_size.R:69

# prequel ----------------------------------------------------------------------
library(testthat)
library(ggplot2)
p0 <- ggplot(mtcars, aes(hp, mpg)) + geom_point()

# test -------------------------------------------------------------------------
skip_if_not_installed("ggforce")
many <- data.frame(x = rep(1:2, 40), y = rep(1:2, 40), g = rep(seq_len(40), each = 2))
paged <- ggplot(many, aes(x, y)) + geom_point() +
    ggforce::facet_wrap_paginate(~g, nrow = 1, ncol = 2, page = 1)
dims <- hv_panel_size(paged)
