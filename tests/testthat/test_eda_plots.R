# tests/testthat/test_eda_plots.R
#
# Tests for eda-plots.R:
#   eda_classify_var(), sample_eda_data(), eda_select_vars(), hv_eda()
#
library(testthat)
library(ggplot2)

# ============================================================================
# eda_classify_var
# ============================================================================

test_that("eda_classify_var returns Cat_Char for a character vector", {
  expect_equal(eda_classify_var(c("A", "B", "A")), "Cat_Char")
})

test_that("eda_classify_var returns Cat_Char for a factor", {
  expect_equal(eda_classify_var(factor(c("low", "high"))), "Cat_Char")
})

test_that("eda_classify_var returns Cat_Num for binary 0/1", {
  expect_equal(eda_classify_var(c(0, 1, 1, 0, NA)), "Cat_Num")
})

test_that("eda_classify_var returns Cat_Num for integer 1-4 within limit", {
  expect_equal(eda_classify_var(c(1L, 2L, 3L, 4L)), "Cat_Num")
})

test_that("eda_classify_var returns Cont when unique count exceeds limit", {
  expect_equal(eda_classify_var(c(1, 2, 3, 4, 5, 6, 7)), "Cont")
})

test_that("eda_classify_var returns Cont for continuous normal data", {
  expect_equal(eda_classify_var(rnorm(50)), "Cont")
})

test_that("eda_classify_var returns Cont for values with decimals", {
  expect_equal(eda_classify_var(c(1.5, 2.5, 3.0)), "Cont")
})

test_that("eda_classify_var returns Cont for negative values", {
  expect_equal(eda_classify_var(c(-1, 0, 1)), "Cont")
})

test_that("eda_classify_var all-NA numeric returns Cat_Num (no non-missing values > limit)", {
  # na.omit returns 0 values; 0 unique values <= limit, no negatives, passes integer check
  result <- eda_classify_var(as.numeric(c(NA, NA)))
  expect_equal(result, "Cat_Num")
})

test_that("eda_classify_var respects custom unique_limit", {
  # With limit = 10, a 7-level integer vector should be Cat_Num
  expect_equal(eda_classify_var(1:7, unique_limit = 10L), "Cat_Num")
})

# ============================================================================
# sample_eda_data
# ============================================================================

test_that("sample_eda_data returns a data frame", {
  df <- sample_eda_data(n = 50, seed = 1)
  expect_true(is.data.frame(df))
})

test_that("sample_eda_data returns exactly n rows", {
  df <- sample_eda_data(n = 120, seed = 1)
  expect_equal(nrow(df), 120L)
})

test_that("sample_eda_data has all required columns", {
  expected <- c("year", "op_years", "male", "cabg", "nyha",
                "valve_morph", "ef", "lv_mass", "peak_grad")
  df <- sample_eda_data(n = 50, seed = 1)
  expect_true(all(expected %in% names(df)))
})

test_that("sample_eda_data year falls within year_range", {
  df <- sample_eda_data(n = 200, year_range = c(2010L, 2018L), seed = 1)
  expect_true(all(df$year >= 2010L))
  expect_true(all(df$year <= 2018L))
})

test_that("sample_eda_data male is binary 0/1", {
  df <- sample_eda_data(n = 200, seed = 1)
  expect_true(all(df$male %in% c(0L, 1L)))
})

test_that("sample_eda_data nyha levels are 1-4", {
  df <- sample_eda_data(n = 200, seed = 1)
  expect_true(all(df$nyha %in% 1L:4L))
})

test_that("sample_eda_data ef has some NA values", {
  df <- sample_eda_data(n = 300, seed = 42)
  expect_true(anyNA(df$ef))
})

test_that("sample_eda_data is reproducible with same seed", {
  df1 <- sample_eda_data(n = 100, seed = 7)
  df2 <- sample_eda_data(n = 100, seed = 7)
  expect_identical(df1, df2)
})

test_that("sample_eda_data differs across seeds", {
  df1 <- sample_eda_data(n = 100, seed = 1)
  df2 <- sample_eda_data(n = 100, seed = 2)
  expect_false(identical(df1, df2))
})

test_that("eda_classify_var identifies ef as Cont in sample data", {
  df <- sample_eda_data(n = 200, seed = 42)
  expect_equal(eda_classify_var(df$ef), "Cont")
})

test_that("eda_classify_var identifies male as Cat_Num in sample data", {
  df <- sample_eda_data(n = 200, seed = 42)
  expect_equal(eda_classify_var(df$male), "Cat_Num")
})

test_that("eda_classify_var identifies valve_morph as Cat_Char in sample data", {
  df <- sample_eda_data(n = 200, seed = 42)
  expect_equal(eda_classify_var(df$valve_morph), "Cat_Char")
})

# ============================================================================
# eda_select_vars
# ============================================================================

test_that("eda_select_vars returns a data frame", {
  df  <- sample_eda_data(n = 50, seed = 1)
  sub <- eda_select_vars(df, c("year", "male"))
  expect_true(is.data.frame(sub))
})

test_that("eda_select_vars vector form returns correct columns in order", {
  df  <- sample_eda_data(n = 50, seed = 1)
  sub <- eda_select_vars(df, c("cabg", "year", "nyha"))
  expect_equal(names(sub), c("cabg", "year", "nyha"))
})

test_that("eda_select_vars space-separated string works like vector form", {
  df   <- sample_eda_data(n = 50, seed = 1)
  sub1 <- eda_select_vars(df, c("year", "male", "cabg"))
  sub2 <- eda_select_vars(df, "year male cabg")
  expect_identical(sub1, sub2)
})

test_that("eda_select_vars trims leading/trailing whitespace in string", {
  df  <- sample_eda_data(n = 50, seed = 1)
  sub <- eda_select_vars(df, "  year  male  ")
  expect_equal(names(sub), c("year", "male"))
})

test_that("eda_select_vars returns the correct number of rows", {
  df  <- sample_eda_data(n = 80, seed = 1)
  sub <- eda_select_vars(df, c("year", "ef"))
  expect_equal(nrow(sub), 80L)
})

test_that("eda_select_vars errors when data is not a data frame", {
  expect_error(eda_select_vars(list(a = 1), "a"), "data frame")
})

test_that("eda_select_vars errors when a column is absent", {
  df <- sample_eda_data(n = 50, seed = 1)
  expect_error(eda_select_vars(df, c("year", "nonexistent")), "column")
})

# ============================================================================
# hv_eda — continuous path
# ============================================================================

test_that("hv_eda returns an hv_data object", {
  df <- sample_eda_data(n = 100, seed = 1)
  expect_s3_class(hv_eda(df, x_col = "op_years", y_col = "ef"), "hv_data")
})

test_that("plot(hv_eda) returns a ggplot for a continuous variable", {
  df <- sample_eda_data(n = 100, seed = 1)
  p  <- plot(hv_eda(df, x_col = "op_years", y_col = "ef"))
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_eda) continuous has a geom_point layer", {
  df    <- sample_eda_data(n = 100, seed = 1)
  geoms <- sapply(
    plot(hv_eda(df, y_col = "ef", x_col = "op_years"))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomPoint" %in% geoms)
})

test_that("plot(hv_eda) continuous has a geom_smooth layer", {
  df    <- sample_eda_data(n = 100, seed = 1)
  geoms <- sapply(
    plot(hv_eda(df, y_col = "ef", x_col = "op_years"))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomSmooth" %in% geoms)
})

test_that("plot(hv_eda) continuous adds geom_rug when y has missing values", {
  df    <- sample_eda_data(n = 200, seed = 42)   # ef has ~8% NA
  geoms <- sapply(
    plot(hv_eda(df, y_col = "ef", x_col = "op_years"))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomRug" %in% geoms)
})

test_that("plot(hv_eda) continuous omits geom_rug when y has no missing values", {
  df      <- sample_eda_data(n = 100, seed = 1)
  df$lv_mass <- df$lv_mass  # lv_mass has no NA by construction
  # Confirm no NA
  expect_false(anyNA(df$lv_mass))
  geoms <- sapply(
    plot(hv_eda(df, y_col = "lv_mass", x_col = "op_years"))$layers,
    function(l) class(l$geom)[1]
  )
  expect_false("GeomRug" %in% geoms)
})

test_that("plot(hv_eda) continuous y_label sets plot title", {
  df <- sample_eda_data(n = 100, seed = 1)
  p  <- plot(hv_eda(df, y_col = "ef", x_col = "op_years",
                      y_label = "Ejection Fraction (%)"))
  expect_equal(p$labels$title, "Ejection Fraction (%)")
})

test_that("plot(hv_eda) continuous falls back to y_col as title when y_label is NULL", {
  df <- sample_eda_data(n = 100, seed = 1)
  p  <- plot(hv_eda(df, y_col = "ef", x_col = "op_years"))
  expect_equal(p$labels$title, "ef")
})

# ============================================================================
# hv_eda — Cat_Num (numeric categorical) path
# ============================================================================

test_that("plot(hv_eda) returns a ggplot for a Cat_Num variable", {
  df <- sample_eda_data(n = 100, seed = 1)
  p  <- plot(hv_eda(df, x_col = "year", y_col = "male"))
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_eda) Cat_Num has a geom_bar layer", {
  df    <- sample_eda_data(n = 100, seed = 1)
  geoms <- sapply(
    plot(hv_eda(df, x_col = "year", y_col = "male"))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomBar" %in% geoms)
})

test_that("plot(hv_eda) Cat_Num show_percent=TRUE adds a y scale", {
  df        <- sample_eda_data(n = 100, seed = 1)
  p_count   <- plot(hv_eda(df, y_col = "male", show_percent = FALSE))
  p_percent <- plot(hv_eda(df, y_col = "male", show_percent = TRUE))
  expect_gt(length(p_percent$scales$scales),
            length(p_count$scales$scales))
})

test_that("plot(hv_eda) Cat_Num y_label sets fill legend name", {
  df <- sample_eda_data(n = 100, seed = 1)
  p  <- plot(hv_eda(df, y_col = "male", y_label = "Sex"))
  expect_equal(p$labels$fill, "Sex")
})

test_that("plot(hv_eda) Cat_Num factor levels include (Missing) last", {
  df            <- sample_eda_data(n = 300, seed = 42)
  df$male[1:10] <- NA
  p             <- plot(hv_eda(df, x_col = "year", y_col = "male"))
  levs          <- levels(p$data$fill)
  expect_equal(tail(levs, 1), "(Missing)")
})

# ============================================================================
# hv_eda — Cat_Char (character categorical) path
# ============================================================================

test_that("plot(hv_eda) returns a ggplot for a Cat_Char variable", {
  df <- sample_eda_data(n = 100, seed = 1)
  p  <- plot(hv_eda(df, x_col = "year", y_col = "valve_morph"))
  expect_s3_class(p, "ggplot")
})

test_that("plot(hv_eda) Cat_Char has a geom_bar layer", {
  df    <- sample_eda_data(n = 100, seed = 1)
  geoms <- sapply(
    plot(hv_eda(df, x_col = "year", y_col = "valve_morph"))$layers,
    function(l) class(l$geom)[1]
  )
  expect_true("GeomBar" %in% geoms)
})

test_that("plot(hv_eda) Cat_Char factor levels preserve original level order", {
  df   <- sample_eda_data(n = 300, seed = 42)
  p    <- plot(hv_eda(df, x_col = "year", y_col = "valve_morph"))
  levs <- levels(p$data$fill)
  expect_equal(tail(levs, 1), "(Missing)")
})

test_that("plot(hv_eda) Cat_Char y_label sets fill legend name", {
  df <- sample_eda_data(n = 100, seed = 1)
  p  <- plot(hv_eda(df, y_col = "valve_morph", y_label = "Valve Morphology"))
  expect_equal(p$labels$fill, "Valve Morphology")
})

# ============================================================================
# hv_eda — error handling
# ============================================================================

test_that("hv_eda errors when data is not a data frame", {
  expect_error(hv_eda(list(a = 1)), "data frame")
})

test_that("hv_eda errors when x_col is absent from data", {
  df <- sample_eda_data(n = 50, seed = 1)
  expect_error(hv_eda(df, x_col = "nonexistent"), "column")
})

test_that("hv_eda errors when y_col is absent from data", {
  df <- sample_eda_data(n = 50, seed = 1)
  expect_error(hv_eda(df, y_col = "nonexistent"), "column")
})

# ============================================================================
# hv_eda — composability
# ============================================================================

test_that("plot(hv_eda) is composable with labs()", {
  df <- sample_eda_data(n = 100, seed = 1)
  p  <- plot(hv_eda(df, y_col = "ef", x_col = "op_years")) +
    ggplot2::labs(x = "Years")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$x, "Years")
})

test_that("plot(hv_eda) is composable with theme_hv_manuscript()", {
  df <- sample_eda_data(n = 100, seed = 1)
  p  <- plot(hv_eda(df, y_col = "male")) + theme_hv_manuscript()
  expect_s3_class(p, "ggplot")
})

# ---------------------------------------------------------------------------
# print.hv_eda coverage
# ---------------------------------------------------------------------------

test_that("print.hv_eda produces <hv_eda> header", {
  df  <- sample_eda_data(n = 100, seed = 1)
  obj <- hv_eda(df, y_col = "male")
  expect_output(print(obj), "<hv_eda>")
})

test_that("print.hv_eda returns x invisibly", {
  df  <- sample_eda_data(n = 100, seed = 1)
  obj <- hv_eda(df, y_col = "male")
  ret <- withVisible(print(obj))
  expect_false(ret$visible)
  expect_identical(ret$value, obj)
})
