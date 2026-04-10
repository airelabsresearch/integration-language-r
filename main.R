#' Entry point — compute LCOE from bundled cost data.
#'
#' Reads a dataset name, target year, discount rate, and project lifetime
#' from the Aire Labs platform, loads cost assumptions from a CSV built
#' into the Docker image, and computes Levelized Cost of Energy.

source("R/airelabs.R")
source("R/model.R")
source("R/data_lookup.R")

main <- function() {
  params <- read_hook_input()

  dataset        <- require_string(params, "dataset")
  target_year    <- as.integer(require_number(params, "target_year"))
  discount_rate  <- require_number(params, "discount_rate")
  lifetime_years <- as.integer(require_number(params, "lifetime_years", expected_unit = "years"))

  # Load cost assumptions from the bundled CSV
  costs <- load_cost_assumptions(dataset, target_year)

  # Return an error result (not a crash) if discount_rate is invalid.
  # The platform marks the LCOE cell as an error and propagates to
  # downstream formulas, while other outputs still get their values.
  if (discount_rate <= 0) {
    write_hook_output(list(
      string_result("dataset",          dataset),
      number_result("capex",            costs$capex,           "USD/kW"),
      number_result("opex",             costs$opex,            "USD/kW/yr"),
      number_result("capacity_factor",  costs$capacity_factor),
      error_result("lcoe",              "INVALID_DISCOUNT_RATE")
    ))
    message(sprintf("ERROR — discount_rate must be positive, got %.4f", discount_rate))
    return(invisible(NULL))
  }

  lcoe <- compute_lcoe(
    capex           = costs$capex,
    opex            = costs$opex,
    capacity_factor = costs$capacity_factor,
    discount_rate   = discount_rate,
    lifetime_years  = lifetime_years
  )

  write_hook_output(list(
    string_result("dataset",          dataset),
    number_result("capex",            costs$capex,           "USD/kW"),
    number_result("opex",             costs$opex,            "USD/kW/yr"),
    number_result("capacity_factor",  costs$capacity_factor),
    number_result("lcoe",             lcoe,                  "USD/MWh")
  ))

  message(sprintf("OK — dataset=%s, year=%d, lcoe=%.2f USD/MWh", dataset, target_year, lcoe))
}

tryCatch(
  main(),
  error = function(e) {
    message("Error: ", conditionMessage(e))
    quit(status = 1)
  }
)
