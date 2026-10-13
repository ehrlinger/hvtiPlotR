# Extracted from test_panel_size.R:76

# prequel ----------------------------------------------------------------------
library(testthat)
library(ggplot2)
p0 <- ggplot(mtcars, aes(hp, mpg)) + geom_point()

# test -------------------------------------------------------------------------
p <- p0 + facet_wrap(~cyl)
inches <- hv_panel_size(p)
