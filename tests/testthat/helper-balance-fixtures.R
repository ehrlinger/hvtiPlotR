# Fixtures for hv_balance() input adapters. Each builder needs cobalt and/or
# hvtiRpropensity; callers guard with skip_if_not_installed().

# Simulated cohort with `n_terms` covariates (alternating continuous and
# binary) and a treatment driven by the first few.
balance_cohort <- function(n_terms = 38, n = 400, seed = 1) {
  withr::local_seed(seed)
  x <- lapply(seq_len(n_terms), function(j) {
    if (j %% 2) stats::rnorm(n) else stats::rbinom(n, 1, 0.4)
  })
  names(x) <- sprintf("x%02d", seq_len(n_terms))
  d <- as.data.frame(x)
  lp <- 0.8 * d$x01 + 0.6 * d$x03 - 0.5 * d$x02
  d$treat <- stats::rbinom(n, 1, stats::plogis(lp))
  d
}

# bal.tab of a cohort with SMD, variance ratio and KS, unadjusted and weighted.
balance_baltab <- function(d, binary = "std") {
  covs <- setdiff(names(d), "treat")
  ps   <- stats::fitted(stats::glm(treat ~ ., data = d, family = stats::binomial()))
  w    <- ifelse(d$treat == 1, 1 / ps, 1 / (1 - ps))
  cobalt::bal.tab(d[covs], treat = d$treat, weights = w, binary = binary,
                  s.d.denom = "pooled", stats = c("m", "v", "ks"), un = TRUE)
}

# Three-group bal.tab.multi with all pairwise comparisons, unadjusted. cobalt
# 5.0.0 does not export `.all`; leaving `which.treat` at its default already
# returns every pair (B vs. A, C vs. A, C vs. B).
balance_baltab_multi <- function(n = 600, seed = 2) {
  withr::local_seed(seed)
  d <- data.frame(age = stats::rnorm(n, 70, 8), female = stats::rbinom(n, 1, 0.4))
  d$grp <- sample(c("A", "B", "C"), n, replace = TRUE)
  cobalt::bal.tab(d[c("age", "female")], treat = d$grp, binary = "std",
                  s.d.denom = "pooled", stats = c("m", "v", "ks"))
}

# Exact mean balance with a distributional gap: both groups have mean 0
# exactly, but treated values sit at +/-1.5 while controls are normal. Every
# SMD is 0; the KS statistic is large.
balance_exact_mean <- function(n = 400, seed = 3) {
  withr::local_seed(seed)
  ctl <- stats::rnorm(n)
  trt <- sample(c(-1.5, 1.5), n, replace = TRUE) + stats::rnorm(n, sd = 0.1)
  d <- data.frame(treat = rep(0:1, each = n),
                  year  = c(ctl - mean(ctl), trt - mean(trt)),
                  age   = stats::rnorm(2 * n))
  d$age <- d$age - stats::ave(d$age, d$treat)
  cobalt::bal.tab(d[c("year", "age")], treat = d$treat, binary = "std",
                  s.d.denom = "pooled", stats = c("m", "v", "ks"))
}
