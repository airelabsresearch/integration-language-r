#' LCOE (Levelized Cost of Energy) calculator.
#'
#' Computes the cost of generating one MWh of electricity over a project's
#' lifetime using the standard formula:
#'
#'   LCOE = (capex * CRF + opex) / (capacity_factor * 8760) * 1000
#'
#' where CRF (Capital Recovery Factor) converts a lump-sum capex into an
#' equivalent annual payment:
#'
#'   CRF = r * (1 + r)^n / ((1 + r)^n - 1)
#'
#' Pure business logic — no knowledge of JSON, Docker, or Aire Labs.
#' You can source() this file in RStudio and call compute_lcoe() directly.

HOURS_PER_YEAR <- 8760

#' Compute the Capital Recovery Factor.
capital_recovery_factor <- function(discount_rate, lifetime_years) {
  if (discount_rate <= 0) stop("discount_rate must be positive")
  if (lifetime_years <= 0) stop("lifetime_years must be positive")
  r <- discount_rate
  n <- lifetime_years
  r * (1 + r)^n / ((1 + r)^n - 1)
}

#' Compute LCOE in USD/MWh from cost assumptions.
compute_lcoe <- function(capex, opex, capacity_factor, discount_rate, lifetime_years) {
  if (capacity_factor <= 0 || capacity_factor > 1) {
    stop("capacity_factor must be between 0 and 1")
  }
  crf <- capital_recovery_factor(discount_rate, lifetime_years)
  lcoe_per_kwh <- (capex * crf + opex) / (capacity_factor * HOURS_PER_YEAR)
  lcoe_per_kwh * 1000
}
