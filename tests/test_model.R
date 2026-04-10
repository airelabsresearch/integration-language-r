#' Unit tests for the LCOE model.
#' Run with:  Rscript tests/test_model.R

source("R/model.R")
source("R/data_lookup.R")

# ── Helpers ──────────────────────────────────────────────────────────────────

assert_equal <- function(actual, expected, tol = 0.01, label = "") {
  if (abs(actual - expected) > tol) {
    stop(sprintf("FAIL %s: expected %.4f, got %.4f", label, expected, actual))
  }
}

assert_error <- function(expr, label = "") {
  tryCatch(
    { expr; stop(sprintf("FAIL %s: expected an error but none occurred", label)) },
    error = function(e) {
      if (grepl("expected an error", conditionMessage(e))) stop(e)
    }
  )
}

# ── CRF ──────────────────────────────────────────────────────────────────────

test_crf <- function() {
  # CRF at 8%, 25yr: manually = 0.08 * 1.08^25 / (1.08^25 - 1)
  r <- 0.08; n <- 25
  expected <- r * (1 + r)^n / ((1 + r)^n - 1)
  assert_equal(capital_recovery_factor(0.08, 25), expected, tol = 1e-8, label = "crf")
  message("PASS: test_crf")
}

test_crf_rejects_bad_inputs <- function() {
  assert_error(capital_recovery_factor(0, 25), label = "zero rate")
  assert_error(capital_recovery_factor(-0.05, 25), label = "negative rate")
  assert_error(capital_recovery_factor(0.08, 0), label = "zero lifetime")
  message("PASS: test_crf_rejects_bad_inputs")
}

# ── LCOE ─────────────────────────────────────────────────────────────────────

test_solar_lcoe <- function() {
  # Solar 2027: capex=960, opex=16.5, cf=0.28, discount=8%, lifetime=25yr
  lcoe <- compute_lcoe(960, 16.5, 0.28, 0.08, 25)

  # Manual: CRF = 0.09368, LCOE = (960 * 0.09368 + 16.5) / (0.28 * 8760) * 1000
  r <- 0.08; n <- 25
  crf <- r * (1 + r)^n / ((1 + r)^n - 1)
  expected <- (960 * crf + 16.5) / (0.28 * 8760) * 1000
  assert_equal(lcoe, expected, tol = 0.01, label = "solar lcoe")

  # Sanity: solar LCOE should be 30-80 $/MWh range
  stopifnot(lcoe > 30 && lcoe < 80)
  message(sprintf("PASS: test_solar_lcoe (%.2f USD/MWh)", lcoe))
}

test_wind_lcoe <- function() {
  # Wind 2030: capex=1150, opex=37.5, cf=0.37
  lcoe <- compute_lcoe(1150, 37.5, 0.37, 0.08, 25)
  stopifnot(lcoe > 30 && lcoe < 100)
  message(sprintf("PASS: test_wind_lcoe (%.2f USD/MWh)", lcoe))
}

test_lcoe_rejects_bad_capacity_factor <- function() {
  assert_error(compute_lcoe(960, 16.5, 0, 0.08, 25), label = "zero cf")
  assert_error(compute_lcoe(960, 16.5, 1.5, 0.08, 25), label = "cf > 1")
  message("PASS: test_lcoe_rejects_bad_capacity_factor")
}

# ── Data lookup ──────────────────────────────────────────────────────────────

test_load_solar <- function() {
  costs <- load_cost_assumptions("solar", 2027)
  stopifnot(costs$capex == 960)
  stopifnot(costs$opex == 16.5)
  stopifnot(costs$capacity_factor == 0.28)
  message("PASS: test_load_solar")
}

test_unknown_dataset <- function() {
  assert_error(load_cost_assumptions("geothermal", 2027), label = "unknown dataset")
  message("PASS: test_unknown_dataset")
}

test_unknown_year <- function() {
  assert_error(load_cost_assumptions("solar", 2050), label = "unknown year")
  message("PASS: test_unknown_year")
}

# ── Run all ──────────────────────────────────────────────────────────────────

test_crf()
test_crf_rejects_bad_inputs()
test_solar_lcoe()
test_wind_lcoe()
test_lcoe_rejects_bad_capacity_factor()
test_load_solar()
test_unknown_dataset()
test_unknown_year()
message("\nAll model tests passed.")
