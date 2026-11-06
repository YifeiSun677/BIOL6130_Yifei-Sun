# 01_download.R — download Birdata surveys (ALA, galah) + 2019-20 fire extent (NIAFED),
# and build the survey x species detection table used by fire_birds.Rmd.
#
# Run from the repository root (the folder that holds fire_birds.Rmd):
#   source("data/01_download.R")
# Writes: data/birdata_raw.csv, data/surveys.csv, data/detections_long.csv
# ---------------------------------------------------------------------------

source("data/config.R")

pkgs <- c("galah", "dplyr", "readr", "tidyr", "sf", "tibble", "rlang")
need <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(need)) install.packages(need)

library(dplyr)
library(galah)
library(readr)
library(tidyr)
library(sf)

dir.create(fire_dir, recursive = TRUE, showWarnings = FALSE)
options(timeout = 3600)   # big files

# ===========================================================================
# 1. BIRDS — Birdata via ALA
# ===========================================================================
ALA_EMAIL <- "YOUR_ALA_EMAIL"   # <-- the email of your (free) ALA account
galah_config(email = ALA_EMAIL, atlas = "Australia", verbose = TRUE)

raw_file <- file.path(data_dir, "birdata_raw.csv")

if (!file.exists(raw_file)) {

  # 1a. Find the Birdata data resource(s)
  ds <- search_all(datasets, "Birdata")
  id_col <- intersect(c("id", "uid"), names(ds))[1]   # galah >= 2.0 calls it "id"
  print(ds[, c(id_col, "name")], n = Inf)
  birdata_uids <- ds[[id_col]][grepl("birdata", ds$name, ignore.case = TRUE)]
  if (length(birdata_uids) == 0) stop("No dataset with 'Birdata' in its name - check the printed list.")
  message("Using data resource(s): ", paste(birdata_uids, collapse = ", "),
          "\n  -> if one of these is NOT the BirdLife Australia Birdata survey dataset, edit birdata_uids.")

  bbox_tbl <- tibble::tibble(xmin = region_bbox[["xmin"]], ymin = region_bbox[["ymin"]],
                             xmax = region_bbox[["xmax"]], ymax = region_bbox[["ymax"]])

  make_req <- function(uid) {
    galah_call() |>
      filter(dataResourceUid == !!uid,
             year >= !!year_min,
             year <= !!year_max) |>
      geolocate(bbox_tbl, type = "bbox")
  }

  # 1b. How many records? (check before downloading)
  for (u in birdata_uids) {
    n <- make_req(u) |> count() |> collect()
    message(u, ": ", n$count, " records in region/years")
  }

  # 1c. Download. 'basic' = coords, date, name, occurrenceStatus;
  #     'event' = eventID, samplingProtocol, etc. (needed to rebuild survey lists)
  raw <- bind_rows(lapply(birdata_uids, function(u) {
    make_req(u) |>
      select(group = c("basic", "event")) |>
      atlas_occurrences()
  }))
  write_csv(raw, raw_file)
} else {
  message("Found ", raw_file, " - skipping ALA download (delete it to re-download).")
  raw <- read_csv(raw_file, show_col_types = FALSE)
}

message("Raw records: ", nrow(raw), "\nColumns: ", paste(names(raw), collapse = ", "))

# ===========================================================================
# 2. Rebuild SURVEYS (each Birdata survey = one species list)
# ===========================================================================
raw <- raw |>
  mutate(date = as.Date(substr(as.character(eventDate), 1, 10)),
         lat  = decimalLatitude,
         lon  = decimalLongitude,
         # tidy names: drop subgenus "(...)" and subspecies -> "Genus species"
         sp   = gsub("\\s*\\([^)]*\\)", "", scientificName),
         sp   = sub("^(\\S+\\s+\\S+).*$", "\\1", sp)) |>
  filter(!is.na(date), !is.na(lat), !is.na(lon))

# 2a. Protocol: keep standard 2-ha 20-min searches if the field is filled
if ("samplingProtocol" %in% names(raw) && mean(!is.na(raw$samplingProtocol)) > 0.5) {
  print(count(raw, samplingProtocol, sort = TRUE), n = 30)
  is_2ha <- grepl("2\\s*-?\\s*ha|20\\s*-?\\s*min", raw$samplingProtocol, ignore.case = TRUE) &
            !grepl("non", raw$samplingProtocol, ignore.case = TRUE)   # drop "2ha, non-20 minute search"
  if (any(is_2ha)) {
    raw <- raw[is_2ha, ]
    message("Kept 2-ha/20-min records: ", nrow(raw))
  } else warning("No samplingProtocol matched '2 ha / 20 min' - look at the table above and edit the pattern.")
} else warning("samplingProtocol mostly empty - keeping all survey types (effort NOT standardised).")

# 2b. Survey ID: eventID if available, otherwise location + date
if ("eventID" %in% names(raw) && mean(!is.na(raw$eventID)) > 0.9) {
  raw$survey_id <- as.character(raw$eventID)
  message("Survey ID = eventID")
} else {
  raw$survey_id <- paste(round(raw$lat, 5), round(raw$lon, 5), raw$date, sep = "_")
  warning("eventID missing - survey ID built from coordinates + date (approximate).")
}

# 2c. Site: locationID if available, otherwise rounded coordinates
if ("locationID" %in% names(raw) && mean(!is.na(raw$locationID)) > 0.9) {
  raw$site <- as.character(raw$locationID)
} else {
  raw$site <- paste(round(raw$lat / site_round) * site_round,
                    round(raw$lon / site_round) * site_round, sep = "_")
}

season_of <- function(m) factor(c("summer", "summer", "autumn", "autumn", "autumn", "winter",
                                  "winter", "winter", "spring", "spring", "spring", "summer")[m],
                                levels = c("summer", "autumn", "winter", "spring"))

surveys <- raw |>
  group_by(survey_id) |>
  summarise(site = first(site), date = first(date),
            lat = mean(lat), lon = mean(lon), n_species = n_distinct(sp), .groups = "drop") |>
  mutate(period = case_when(date >= before_start & date <= before_end ~ "before",
                            date >= after_start  & date <= after_end  ~ "after",
                            TRUE ~ NA_character_),
         month  = as.integer(format(date, "%m")),
         season = season_of(month),
         year   = as.integer(format(date, "%Y")),
         yrs_since_fire = ifelse(period == "after",
                                 as.numeric(date - fire_ref_date) / 365.25, 0)) |>
  filter(!is.na(period))

if (require_both_periods) {
  both <- surveys |> distinct(site, period) |> count(site) |> filter(n == 2) |> pull(site)
  surveys <- filter(surveys, site %in% both)
}
message("Surveys: ", nrow(surveys), " at ", n_distinct(surveys$site), " sites")

# ===========================================================================
# 3. FIRE — 2019-20 fire extent (NIAFED, DCCEEW)
# ===========================================================================
niafed_url <- "https://fed.dcceew.gov.au/api/download/v1/items/dc651afe7ec944d0a22e6c1f120f3a15/shapefile?layers=0"
fire_zip   <- file.path(fire_dir, "niafed.zip")

shp <- list.files(fire_dir, pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
if (length(shp) == 0) {
  if (!file.exists(fire_zip)) {
    # curl follows the redirects to the ArcGIS/Azure file (download.file() fails on them).
    # The portal may first reply with a small JSON "file is being generated" note instead of
    # the zip, so retry until the file really is a zip, and only then keep it.
    ok <- FALSE
    tmp <- tempfile(fileext = ".zip")
    for (i in 1:10) {
      got <- tryCatch({ curl::curl_download(niafed_url, tmp); TRUE },
                      error = function(e) { message(e$message); FALSE })
      if (got && identical(readBin(tmp, "raw", 2), charToRaw("PK"))) { ok <- file.copy(tmp, fire_zip); break }
      if (got) message("Fire server says: ", paste(readLines(tmp, warn = FALSE), collapse = " "))
      message("Fire layer not ready - retrying in 30 s (", i, "/10)")
      Sys.sleep(30)
    }
    if (!ok) stop("Fire layer download failed. Download the NIAFED shapefile manually from\n",
                  "https://www.data.gov.au/data/dataset/erin-national-indicative-aggregated-fire-extent-dataset\n",
                  "and unzip it into ", fire_dir)
  }
  unzip(fire_zip, exdir = fire_dir)
  shp <- list.files(fire_dir, pattern = "\\.shp$", recursive = TRUE, full.names = TRUE)
}

sf_use_s2(FALSE)
fire <- st_read(shp[1], quiet = TRUE)
message("Fire layer: ", nrow(fire), " polygons. Fields: ", paste(names(fire), collapse = ", "))

# keep only 2019-20 fires if the layer holds several seasons
season_col <- grep("season", names(fire), ignore.case = TRUE, value = TRUE)
date_col   <- names(fire)[vapply(st_drop_geometry(fire), inherits, logical(1), what = c("Date", "POSIXt"))]
if (length(season_col)) {
  keep <- grepl("2019", fire[[season_col[1]]])
  message("Filtering on ", season_col[1], ": keeping ", sum(keep), " polygons with '2019'")
  fire <- fire[keep, ]
} else if (length(date_col)) {
  d <- as.Date(fire[[date_col[1]]])
  keep <- !is.na(d) & d >= as.Date("2019-07-01") & d <= as.Date("2020-03-31")
  message("Filtering on ", date_col[1], ": keeping ", sum(keep), " polygons dated Jul 2019 - Mar 2020")
  fire <- fire[keep, ]
} else {
  message("No season/date field found - treating ALL polygons as 2019-20 fire extent. Check this!")
}

# crop to the region plus a ~20 km margin (so distances near the region edge are right),
# then work in metres (GDA94 / Australian Albers, EPSG:3577)
bb <- st_as_sfc(st_bbox(region_bbox + c(-0.2, -0.2, 0.2, 0.2), crs = st_crs(4326))) |> st_transform(st_crs(fire))
fire <- suppressWarnings(st_crop(st_make_valid(fire), bb)) |> st_transform(3577) |> st_union() |> st_make_valid()

# signed distance from each site to the fire edge (m): negative = inside the fire
sites <- surveys |> group_by(site) |> summarise(lat = mean(lat), lon = mean(lon), .groups = "drop")
sites_sf <- st_as_sf(sites, coords = c("lon", "lat"), crs = 4326) |> st_transform(3577)
inside <- lengths(st_intersects(sites_sf, fire)) > 0
d_edge <- as.numeric(st_distance(sites_sf, st_cast(st_boundary(fire), "MULTILINESTRING")))
sites$fire_dist_m <- round(ifelse(inside, -d_edge, d_edge))
sites$burnt <- as.integer(sites$fire_dist_m <= burnt_threshold_m)
message("Sites burnt: ", sum(sites$burnt), " / ", nrow(sites))

# drop columns from an earlier run of this chunk, so re-running does not make burnt.x / burnt.y
surveys <- surveys |> select(-any_of(c("burnt", "fire_dist_m"))) |>
  left_join(select(sites, site, burnt, fire_dist_m), by = "site")
write_csv(surveys, surveys_file)

# ===========================================================================
# 4. Detection table: every survey x every target species (0/1)
# ===========================================================================
present <- raw |>
  filter(survey_id %in% surveys$survey_id, sp %in% all_target)
if ("occurrenceStatus" %in% names(present))
  present <- filter(present, is.na(occurrenceStatus) | toupper(occurrenceStatus) == "PRESENT")
present <- present |> distinct(survey_id, species = sp) |> mutate(detected = 1L)

detections <- expand_grid(survey_id = surveys$survey_id, species = all_target) |>
  left_join(present, by = c("survey_id", "species")) |>
  mutate(detected = coalesce(detected, 0L)) |>
  left_join(surveys, by = "survey_id")

write_csv(detections, detections_file)

# quick look: reporting rate by species x burnt x period
detections |>
  group_by(species, burnt, period) |>
  summarise(n = n(), rate = round(mean(detected), 3), .groups = "drop") |>
  pivot_wider(names_from = c(burnt, period), values_from = c(n, rate)) |>
  print(width = Inf)

message("Done. Now render fire_birds.Rmd")
