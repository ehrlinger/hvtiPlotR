test_that("sample_correlation_data is deterministic and shaped", {
  a <- sample_correlation_data(n = 50, seed = 1)
  expect_identical(a, sample_correlation_data(n = 50, seed = 1))
  expect_equal(nrow(a), 50L)
  expect_true(all(c("a1c", "glucose", "creatinine", "albumin", "a1c_grp") %in% names(a)))
})

test_that("hv_correlation_matrix builds the lower triangle", {
  d <- sample_correlation_data(n = 100)
  cm <- hv_correlation_matrix(d, vars = c("a1c", "glucose", "creatinine", "albumin"))
  expect_s3_class(cm, c("hv_correlation_matrix", "hv_data"))
  panels <- unique(cm$data[c("col_var", "row_var")])
  expect_equal(nrow(panels), 6L)
  # lower triangle: the row variable always comes after the column variable
  expect_true(all(as.integer(panels$row_var) > as.integer(panels$col_var)))
  expect_equal(nrow(cm$data), 6L * 100L)
})

test_that("rows missing either coordinate are dropped per panel", {
  d <- sample_correlation_data(n = 100)
  d$glucose[1:10] <- NA
  cm <- hv_correlation_matrix(d, vars = c("a1c", "glucose", "albumin"))
  counts <- table(paste(cm$data$col_var, cm$data$row_var))
  expect_equal(as.integer(counts[["a1c glucose"]]), 90L)
  expect_equal(as.integer(counts[["a1c albumin"]]), 100L)
})

test_that("coefficients are the pairwise matrix under labels", {
  d <- sample_correlation_data(n = 100)
  cm <- hv_correlation_matrix(d, vars = c("a1c", "glucose"),
                              labels = c("HbA1c", "Glucose"), method = "spearman")
  expect_equal(dimnames(cm$tables$coefficients)[[1]], c("HbA1c", "Glucose"))
  expect_equal(cm$tables$coefficients[1, 2],
               stats::cor(d$a1c, d$glucose, method = "spearman"))
  expect_equal(levels(cm$data$col_var), c("HbA1c", "Glucose"))
})

test_that("errors are clear", {
  d <- sample_correlation_data(n = 20)
  expect_error(hv_correlation_matrix(d, vars = "a1c"), "at least two")
  expect_error(hv_correlation_matrix(d, vars = c("a1c", "a1c_grp")), "numeric")
  expect_error(hv_correlation_matrix(d, vars = c("a1c", "glucose"), labels = "x"),
               "one label per")
})

test_that("a missing column is reported before the length check", {
  d <- sample_correlation_data(n = 20)
  expect_error(hv_correlation_matrix(d, vars = "nope"), "Missing required column")
})

test_that("duplicate vars is an error", {
  d <- sample_correlation_data(n = 20)
  expect_error(hv_correlation_matrix(d, vars = c("a1c", "a1c", "glucose")),
               "vars.*duplicate")
})

test_that("duplicate labels is an error", {
  d <- sample_correlation_data(n = 20)
  expect_error(
    hv_correlation_matrix(d, vars = c("a1c", "glucose"), labels = c("x", "x")),
    "labels"
  )
})

test_that("an NA label is an error", {
  d <- sample_correlation_data(n = 20)
  expect_error(
    hv_correlation_matrix(d, vars = c("a1c", "glucose"), labels = c("x", NA_character_)),
    "labels"
  )
})

test_that("numeric labels are an error", {
  d <- sample_correlation_data(n = 20)
  expect_error(
    hv_correlation_matrix(d, vars = c("a1c", "glucose"), labels = c(1, 2)),
    "labels"
  )
})

test_that("degenerate variables warn once, naming each of them", {
  d <- sample_correlation_data(n = 30)
  d$all_na <- NA_real_
  d$const  <- 5
  expect_warning(
    hv_correlation_matrix(d, vars = c("a1c", "glucose", "all_na", "const")),
    "all_na|const"
  )
})

test_that("plot returns a bare faceted ggplot", {
  cm <- hv_correlation_matrix(sample_correlation_data(n = 50),
                              c("a1c", "glucose", "albumin"))
  p <- plot(cm)
  expect_s3_class(p, "ggplot")
  expect_s3_class(p$facet, "FacetGrid")
  expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
})

test_that("plot panels form a lower triangle", {
  cm <- hv_correlation_matrix(sample_correlation_data(n = 30),
                              c("a1c", "glucose", "creatinine", "albumin"))
  built <- ggplot2::ggplot_build(plot(cm))
  layout <- built$layout$layout
  data_panels <- unique(built$data[[1]]$PANEL)
  has_data <- layout[layout$PANEL %in% data_panels, ]
  expect_equal(nrow(has_data), 6L)
  expect_true(all(has_data$ROW >= has_data$COL))
})
