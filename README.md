# Fire effects on forest birds: guilds and species after the 2019–20 bushfires

BIOL6130 research project — u8179158

## Extended abstract

This study aimed to quantify the effects of the 2019–20 Australian bushfires on forest birds and determine whether responses differed among ground, understorey and canopy guilds and among species within guilds. A before–after–control–impact design compared detections of seven species across affected forests of New South Wales and East Gippsland. The analysis included 1,298 standardised 20-minute surveys at 654 sites. Surveys covered 2015–19 (before fire) and 2020–23 (after fire), excluding the fire season and sites within 2 km of the fire boundary. Binomial generalised linear mixed models estimated burnt × after interactions while controlling background effects.

Fire was associated with an overall decline in detection probability (P = 0.033), with responses differing among guilds (P = 0.016). Understorey birds showed the strongest decline (interaction coefficient δ = −0.836, 95% CI −1.396 to −0.275). There wasn't distinguishable fire effect for ground and canopy species. Crimson Rosella declined more than Grey Shrike-thrush within the canopy guild (P = 0.027), whereas there is no species variation in ground and understorey. 

These findings support prioritising understorey habitat retention and regeneration, including protection of unburnt refuges that may support recolonisation. Species-level variation also indicates that guild averages can conceal individual responses. However, detections do not directly measure occupancy or habitat destruction, so translating these estimates into habitat-loss parameters requires caution. Uncertain detectability, binary fire classification, sensitivity to spatial site selection and pooled post-fire observations limit mechanistic inference. Repeated surveys incorporating detection probability, fire severity and time since fire would better resolve population responses and recovery trajectories.
 



## Reproducing the analysis

**fire_birds.rmd file is self-contained. It takes the filtered dataset in data/ as input.**
**If you want to start by downloading original dataset and do data filtering, please run 01_download.R in data/ folder.**
**Which needs an ALA email and may takes one hour.**

Requirements: R ≥ 4.6 and  packages (versions used for the reported results):

| Package | Version | | Package | Version |
|---|---|---|---|---|
| rmarkdown | 2.31 | | lme4 | 2.0.6 |
| knitr | 1.51 | | MASS | 7.3.65 |
| dplyr | 1.2.1 | | ggplot2 | 4.0.3 |
| readr | 2.2.0 | | patchwork | 1.3.2 |
| tidyr | 1.3.2 | | | |

```bash
git clone https://github.com/YifeiSun677/BIOL6130_Yifei-Sun.git
cd BIOL6130_Yifei-Sun
Rscript -e 'install.packages(c("rmarkdown","knitr","dplyr","readr","tidyr","lme4","MASS","ggplot2","patchwork"))'
Rscript -e 'rmarkdown::render("fire_birds.Rmd")'
```

This produces `fire_birds.html` with all tables and figures. All data are in `data/`, so no download is needed.
The only random step (parametric bootstrap of the habitat-loss CIs) is seeded with `set.seed(1)`.

### Repository layout

| Path | What it is |
|---|---|
| `fire_birds.Rmd` | Full analysis: data filtering, GLMMs (m0–m3), likelihood-ratio tests, contrasts, Levins habitat-loss model, figures |
| `fire_birds.html` | Rendered output of the above |
| `poster.pptx` | Poster source (PDF submitted on Canvas) |
| `data/birdata_raw.csv` | Raw Birdata survey records downloaded from the ALA |
| `data/surveys.csv` | One row per survey: site, date, coordinates, before/after period, season, signed distance to the fire edge (`fire_dist_m`, negative = inside) |
| `data/detections_long.csv` | One row per survey × species: detected (1/0) |
| `data/fire/` | NIAFED fire-extent shapefile used to classify sites as burnt/unburnt |
| `data/01_download.R` | Data preparation: downloads Birdata and NIAFED and builds the three CSVs (see below; optional to re-run) |
| `data/config.R` | Settings for `01_download.R`: region, dates, BACI periods, site size, target species |


## Data provenance

| Dataset | Source and collector | Licence | Cite as |
|---|---|---|---|
| Bird surveys (`birdata_raw.csv`, and the derived `surveys.csv`, `detections_long.csv`) | BirdLife Australia Birdata program; volunteer observers following the standard 2-ha 20-minute search protocol. Downloaded from the Atlas of Living Australia (data resource dr359) with the `galah` R package. | CC BY-NC 4.0 | BirdLife Australia (2026). Birdata. Accessed via the Atlas of Living Australia, https://collections.ala.org.au/public/show/dr359, 22nd, Oct 2026. |
| Fire extent (`data/fire/NIAFED_v20200623.*`) | **National Indicative Aggregated Fire Extent Dataset** v20200623, compiled by the Australian Government Department of Agriculture, Water and the Environment from state and territory fire-mapping data for the 2019–20 season. | CC BY 4.0 | DAWE (2020). National Indicative Aggregated Fire Extent Dataset, v20200623. Department of Agriculture, Water and the Environment, Canberra. |
| Poster figure (adapted) | Legge S. et al. (2022). Diversity and Distributions 28, 571–591. doi:10.1111/ddi.13428 | CC BY 4.0 | as given |

### Data preparation (already done; optional to re-run)

The three CSV files in `data/` were built by `data/01_download.R`, with all settings in `data/config.R`.
They are committed, so `fire_birds.Rmd` renders without re-running this step. To rebuild them, put your own
ALA account email in `ALA_EMAIL` and run `source("data/01_download.R")` from the repository root
(extra packages: `galah`, `sf`, `tibble`, `rlang`). The fire-distance step is slow (up to an hour or more).

1. **Download** (`birdata_raw.csv`). Birdata records (ALA data resource dr359), 2015–2023, within
   lon 147.5–150.6, lat −38.0 to −35.0, with event fields (`eventID`, `samplingProtocol`). Unfiltered.
2. **Surveys** (`surveys.csv`). Only "2ha, 20 minute search" records are kept. One survey = one `eventID`.
   Site = coordinates rounded to 0.002° (~200 m). Period: *before* = 1 Jul 2015 – 31 Jul 2019,
   *after* = 1 Mar 2020 – 31 Dec 2023; the fire season (Aug 2019 – Feb 2020) is dropped. Season is from the month
   (Dec–Feb = summer); `yrs_since_fire` is counted from 1 Jan 2020.
3. **Fire distance**. The NIAFED polygon is cropped to the region (+~20 km), repaired, unioned and projected to
   Australian Albers (EPSG:3577). `fire_dist_m` = distance from each site to the fire edge in metres,
   negative inside the fire; `burnt = fire_dist_m ≤ 0`.
4. **Detections** (`detections_long.csv`). Every survey × 8 target species; `detected = 1` if the species was
   recorded as present in that survey, else 0. Flame Robin and Pied Currawong are included but not used.
5. **In `fire_birds.Rmd`**: forest zones only (Canberra/ACT and inland tablelands dropped), sites within 2 km of
   the fire edge dropped, 7 analysis species kept, and Eastern Yellow Robin added from `birdata_raw.csv`
   (all its records are 2-ha 20-minute searches). Result: 654 sites, 1,298 surveys.
   
## Use of generative AI

- **Claude via Claude Code:** helped write codes, fit GLMM model. Language polish in readme.md
- The extended abstract, the poster text and all interpretations are my own.

## Licence

Code: see `LICENSE`. Data remain under their original licences (above).
