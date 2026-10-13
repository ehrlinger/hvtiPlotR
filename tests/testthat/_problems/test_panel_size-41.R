# Extracted from test_panel_size.R:41

# prequel ----------------------------------------------------------------------
library(testthat)
library(ggplot2)
p0 <- ggplot(mtcars, aes(hp, mpg)) + geom_point()

# test -------------------------------------------------------------------------
p <- p0 + facet_wrap(~cyl)
dims <- hv_panel_size(p)
