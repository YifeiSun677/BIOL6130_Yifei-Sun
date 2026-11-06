# config.R — settings for data/01_download.R
# ---------------------------------------------------------------

# Study region: south-east NSW coast + East Gippsland (lon/lat, WGS84)
region_bbox <- c(xmin = 147.5, ymin = -38.0, xmax = 150.6, ymax = -35.0)

# Years to download
year_min <- 2015
year_max <- 2023

# BACI periods (fire season Aug 2019 - Feb 2020 is dropped)
before_start <- as.Date("2015-07-01")
before_end   <- as.Date("2019-07-31")
after_start  <- as.Date("2020-03-01")
after_end    <- as.Date("2023-12-31")
fire_ref_date <- as.Date("2020-01-01")   # for time-since-fire

# Site definition when no locationID: round coords (0.002 deg ~ 200 m, about a 2-ha plot)
site_round <- 0.002

# Keep only sites surveyed in BOTH periods (cleaner BACI, but drops ~2/3 of surveys).
# FALSE = keep all sites; the site random effect handles sites surveyed in one period only.
require_both_periods <- FALSE

# Burnt = signed distance to the 2019-20 fire edge <= threshold (m); negative = inside the fire
burnt_threshold_m <- 0

# Species written to detections_long.csv.
# Flame Robin and Pied Currawong are kept so the committed CSV is reproduced exactly;
# fire_birds.Rmd does not use them. Eastern Yellow Robin is added in fire_birds.Rmd.
all_target <- c("Menura novaehollandiae", "Malurus cyaneus", "Sericornis frontalis",
                "Acanthiza pusilla", "Petroica phoenicea", "Platycercus elegans",
                "Colluricincla harmonica", "Strepera graculina")

# Paths (relative to the repository root)
data_dir <- "data"
fire_dir <- file.path(data_dir, "fire")
detections_file <- file.path(data_dir, "detections_long.csv")
surveys_file    <- file.path(data_dir, "surveys.csv")
