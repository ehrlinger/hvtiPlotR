# Five exported arguments take both spellings: the US name is documented as
# primary and the British one is kept for existing code. Each pair must give
# identical results from either name alone, and refuse two different values.

dta_sp <- sample_spaghetti_data(n_patients = 40, seed = 3L)

test_that("hv_spaghetti() takes color_col and colour_col alike", {
  us <- hv_spaghetti(dta_sp, color_col = "group")
  uk <- hv_spaghetti(dta_sp, colour_col = "group")
  expect_identical(us, uk)
  expect_identical(us$meta$color_col, "group")
  expect_identical(us$meta$colour_col, "group")
  expect_identical(hv_spaghetti(dta_sp, color_col = "group", colour_col = "group"), us)
  expect_error(hv_spaghetti(dta_sp, color_col = "group", colour_col = "id"),
               "`color_col` and `colour_col`")
  expect_null(hv_spaghetti(dta_sp)$meta$color_col)
})

test_that("plot.hv_spaghetti() takes line_color and line_colour alike", {
  sp <- hv_spaghetti(dta_sp)
  us <- ggplot2::ggplot_build(plot(sp, line_color = "steelblue"))$data[[1]]
  uk <- ggplot2::ggplot_build(plot(sp, line_colour = "steelblue"))$data[[1]]
  expect_identical(us, uk)
  expect_true(all(us$colour == "steelblue"))
  expect_plot_has_data(plot(sp, line_color = "steelblue"))
  expect_error(plot(sp, line_color = "red", line_colour = "blue"),
               "`line_color` and `line_colour`")
})

test_that("hv_sankey() takes node_colors and node_colours alike", {
  dta <- sample_cluster_sankey_data(n = 200, seed = 1)
  cols <- stats::setNames(rep_len(c("#111111", "#222222", "#333333"), 9), LETTERS[1:9])
  us <- hv_sankey(dta, node_colors = cols)
  uk <- hv_sankey(dta, node_colours = cols)
  expect_identical(us, uk)
  expect_identical(us$meta$node_colors, cols)
  expect_identical(us$meta$node_colours, cols)
  dflt <- hv_sankey(dta)
  expect_identical(dflt$meta$node_colors, dflt$meta$node_colours)
  expect_error(hv_sankey(dta, node_colors = cols, node_colours = rev(cols)),
               "`node_colors` and `node_colours`")
})

test_that("hv_ppt_series() takes `colors` and `colours` alike", {
  pal <- c("red", "blue", "green", "orange")
  us <- hv_ppt_series(colors = pal)
  uk <- hv_ppt_series(colours = pal)
  expect_identical(us[[2]]$palette(4), uk[[2]]$palette(4))
  expect_identical(unname(us[[2]]$palette(4)), pal)
  expect_error(hv_ppt_series(colors = pal, colours = rev(pal)), "`colors` and `colours`")
})

test_that("make_footnote() takes `color` and `colour` alike", {
  seen <- character()
  local_mocked_bindings(grid.text = function(..., gp) seen <<- c(seen, gp$col))
  pdf(NULL)
  on.exit(dev.off(), add = TRUE)
  make_footnote("x", color = "red")
  make_footnote("x", colour = "red")
  make_footnote("x")
  expect_identical(seen, c("red", "red", gray(0.5)))
  expect_error(make_footnote("x", color = "red", colour = "blue"), "`color` and `colour`")
  expect_error(make_footnote("x", color = c("red", "blue")), "`color` must be a length-1")
})
