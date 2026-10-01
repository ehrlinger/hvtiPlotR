# Tests for hv_role_palette() and scale_color_hv() / scale_fill_hv().
# The rule is dev/specs/2026-09-27-hv-palette-design.md section 3.
library(testthat)
library(ggplot2)

event_col <- "#D55E00"
censored_col <- "#0072B2"
missing_col <- "#CCCCCC"

# WCAG contrast of a color against white.
contrast_on_white <- function(hex) {
  rgb <- grDevices::col2rgb(hex)[, 1] / 255
  lin <- ifelse(rgb <= 0.04045, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
  1.05 / (sum(c(0.2126, 0.7152, 0.0722) * lin) + 0.05)
}

# ============================================================================
# hv_role_palette
# ============================================================================

test_that("roles take their colors wherever they sit in levels", {
  pal <- hv_role_palette(c("a", "Dead", "(Missing)", "Alive"), event = "Dead", censored = "Alive")
  expect_identical(names(pal), c("a", "Dead", "(Missing)", "Alive"))
  expect_identical(unname(pal[c("Dead", "Alive", "(Missing)")]), c(event_col, censored_col, missing_col))
})

test_that("with no role present the rotation is hv_ppt_palette('light') in level order", {
  pal <- hv_role_palette(c("x", "y", "z"))
  expect_identical(unname(pal), hv_ppt_palette("light", n = 3))
  # A role named but absent from these levels has no effect at all.
  expect_identical(hv_role_palette(c("x", "y", "z"), event = "Dead", censored = "Alive"), pal)
})

test_that("a role in the levels takes blue and vermillion out of the rotation", {
  for (role in list(list(event = "e"), list(censored = "e"))) {
    pal <- do.call(hv_role_palette, c(list(levels = c("e", "p", "q")), role))
    expect_false(any(pal[c("p", "q")] %in% c(event_col, censored_col)))
  }
})

test_that("a sole level is blue with no role, and keeps its role color otherwise", {
  expect_identical(unname(hv_role_palette("only")), censored_col)
  expect_identical(unname(hv_role_palette("d", event = "d")), event_col)
  expect_identical(unname(hv_role_palette("a", censored = "a")), censored_col)
  expect_identical(unname(hv_role_palette("(Missing)")), missing_col)
})

test_that("dp-gfup's event panel draws blue, vermillion and green", {
  pal <- hv_role_palette(c("No event", "Reoperation", "Death"), event = "Death", censored = "No event")
  expect_identical(unname(pal), c(censored_col, "#009E73", event_col))
})

test_that("past the rotation every other level switches to Tol muted", {
  seven <- hv_role_palette(letters[1:7])
  expect_false(any(seven %in% hv_ppt_palette("light")))
  expect_length(unique(seven), 7L)
  # With a role present the rotation holds four, so five others switch, and
  # rose, which reads as the event, is not among them.
  five <- hv_role_palette(c("ev", letters[1:5]), event = "ev")
  expect_false(any(five[letters[1:5]] %in% hv_ppt_palette("light")))
  expect_false("#CC6677" %in% five)
  expect_identical(unname(hv_role_palette(c("ev", letters[1:4]), event = "ev")[letters[1:4]]),
                   c("#009E73", "#CC79A7", "#9D952B", "#000000"))
})

test_that("more levels than any palette holds is a classed error", {
  expect_error(hv_role_palette(letters[1:8]), class = "hv_role_palette_capacity")
  expect_error(hv_role_palette(c("ev", letters[1:7]), event = "ev"), class = "hv_role_palette_capacity")
  expect_error(hv_role_palette(letters[1:8]), "8 levels")
})

test_that("every color but missing clears 2:1 against white", {
  cols <- unique(c(hv_role_palette(letters[1:6]), hv_role_palette(letters[1:7]),
                   hv_role_palette(c("ev", "ce", letters[1:4]), event = "ev", censored = "ce"),
                   hv_role_palette(c("ev", letters[1:6]), event = "ev")))
  ratios <- vapply(cols, contrast_on_white, numeric(1))
  expect_true(all(ratios >= 2), info = paste(names(ratios)[ratios < 2], collapse = ", "))
})

test_that("bad arguments stop with a message naming them", {
  expect_error(hv_role_palette(c("a", "a")), "levels")
  expect_error(hv_role_palette(c("a", NA)), "levels")
  expect_error(hv_role_palette(1:3), "levels")
  expect_error(hv_role_palette(c("a", "b"), event = "a", censored = "a"), "more than one role: a")
  expect_error(hv_role_palette("a", event = 1), "event")
  expect_identical(hv_role_palette(character()), stats::setNames(character(), character()))
})

# ============================================================================
# scale_fill_hv / scale_color_hv
# ============================================================================

bars <- function(levels, n = rep(3L, length(levels))) {
  ggplot(data.frame(g = factor(rep(levels, n), levels = levels)), aes(x = .data[["g"]], fill = .data[["g"]])) +
    geom_bar()
}
built_fill <- function(p) {
  d <- ggplot_build(p)$data[[1]]
  stats::setNames(d$fill, levels(p$data$g)[d$x])
}

test_that("one page scale colors each panel from that panel's own levels", {
  # The event is in the first panel only: the second must get the full rotation.
  page <- (bars(c("Alive", "Dead", "x")) | bars(c("p", "q"))) &
    scale_fill_hv(event = "Dead", censored = "Alive")
  expect_plot_has_data(page[[1]])
  expect_plot_has_data(page[[2]])
  expect_identical(built_fill(page[[1]]), c(Alive = censored_col, Dead = event_col, x = "#009E73"))
  expect_identical(built_fill(page[[2]]), c(p = censored_col, q = event_col))
})

test_that("the legend shows the panel's colors", {
  p <- bars(c("Alive", "Dead")) + scale_fill_hv(event = "Dead", censored = "Alive")
  key <- ggplot2::get_guide_data(p, "fill")
  expect_identical(stats::setNames(key$fill, key$.label), c(Alive = censored_col, Dead = event_col))
})

test_that("a real NA takes the missing gray, and na.value can override it", {
  df <- data.frame(x = 1:4, y = 1:4, g = c("a", "b", NA, "a"))
  p <- ggplot(df, aes(x, y, color = g)) + geom_point()
  pts <- ggplot_build(p + scale_color_hv())$data[[1]]
  expect_plot_has_data(p + scale_color_hv())
  expect_identical(pts$colour[3], missing_col)
  expect_identical(pts$colour[c(1, 2)], hv_ppt_palette("light", n = 2))
  expect_identical(ggplot_build(p + scale_color_hv(na.value = "black"))$data[[1]]$colour[3], "black")
  # na.translate = FALSE drops the NA point, as it does on any ggplot2 scale.
  expect_true(is.na(ggplot_build(p + scale_color_hv(na.translate = FALSE))$data[[1]]$colour[3]))
})

test_that("scale_colour_hv() is the same function as scale_color_hv()", {
  expect_identical(scale_colour_hv, scale_color_hv)
  # load_all() sees unexported objects, so check the export itself: code before 2.8.0 calls it.
  expect_true("scale_colour_hv" %in% getNamespaceExports("hvtiPlotR"))
})

test_that("a panel with too many levels warns once and draws ggplot's default hue", {
  p <- bars(letters[1:9]) + scale_fill_hv()
  expect_warning(fills <- built_fill(p), "9 levels")
  expect_length(unique(fills), 9L)
  expect_false(any(fills %in% hv_ppt_palette("light")))
  n_warn <- 0L
  withCallingHandlers(ggplot_build(p), warning = function(w) {
    n_warn <<- n_warn + 1L
    invokeRestart("muffleWarning")
  })
  expect_identical(n_warn, 1L)
})

test_that("the scales pass ... to discrete_scale", {
  p <- bars(c("a", "b")) + scale_fill_hv(name = "Group", labels = c(a = "A", b = "B"))
  key <- ggplot2::get_guide_data(p, "fill")
  expect_identical(as.character(key$.label), c("A", "B"))
  expect_identical(ggplot_build(p)$plot$scales$get_scales("fill")$name, "Group")
})
