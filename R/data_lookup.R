#' Load cost assumptions from a bundled CSV dataset.
#'
#' The data/ directory contains CSV files built into the Docker image.
#' Each file represents a generation technology (solar, wind) with
#' year-by-year cost projections.

DATA_DIR <- "data"

#' List available datasets (file stems in data/).
available_datasets <- function() {
  files <- list.files(DATA_DIR, pattern = "\\.csv$")
  tools::file_path_sans_ext(files)
}

#' Load cost assumptions for a technology and year.
#' Returns a list with capex, opex, and capacity_factor.
#' Stops with a clear error if the dataset or year is not found.
load_cost_assumptions <- function(dataset, target_year) {
  datasets <- available_datasets()
  if (!(dataset %in% datasets)) {
    stop(sprintf(
      "unknown dataset '%s' — available datasets: %s",
      dataset,
      paste(datasets, collapse = ", ")
    ))
  }

  path <- file.path(DATA_DIR, paste0(dataset, ".csv"))
  df <- read.csv(path, stringsAsFactors = FALSE)

  row <- df[df$year == target_year, ]
  if (nrow(row) == 0) {
    years <- paste(df$year, collapse = ", ")
    stop(sprintf(
      "year %d not found in '%s' dataset — available years: %s",
      target_year, dataset, years
    ))
  }

  list(
    capex           = row$capex_usd_per_kw,
    opex            = row$opex_usd_per_kw_yr,
    capacity_factor = row$capacity_factor
  )
}
