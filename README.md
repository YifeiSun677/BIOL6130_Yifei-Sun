# Fire effects on forest birds: guilds and species after the 2019–20 bushfires

BIOL6130 research project — u8179158

## Extended abstract

This study aimed to quantify the effects of the 2019–20 Australian bushfires on forest birds and determine whether responses differed among ground, understorey and canopy guilds and among species within guilds. A before–after–control–impact design compared detections of seven species across affected forests of New South Wales and East Gippsland. The analysis included 1,298 standardised 20-minute surveys at 654 sites. Surveys covered 2015–19 (before fire) and 2020–23 (after fire), excluding the fire season and sites within 2 km of the fire boundary. Binomial generalised linear mixed models estimated burnt × after interactions while controlling background effects.

Fire was associated with an overall decline in detection probability (P = 0.033), with responses differing among guilds (P = 0.016). Understorey birds showed the strongest decline (interaction coefficient δ = −0.836, 95% CI −1.396 to −0.275). There wasn't distinguishable fire effect for ground and canopy species. Crimson Rosella declined more than Grey Shrike-thrush within the canopy guild (P = 0.027), whereas there is no species variation in ground and understorey. 

These findings support prioritising understorey habitat retention and regeneration, including protection of unburnt refuges that may support recolonisation. Species-level variation also indicates that guild averages can conceal individual responses. However, detections do not directly measure occupancy or habitat destruction, so translating these estimates into habitat-loss parameters requires caution. Uncertain detectability, binary fire classification, sensitivity to spatial site selection and pooled post-fire observations limit mechanistic inference. Repeated surveys incorporating detection probability, fire severity and time since fire would better resolve population responses and recovery trajectories.
 



## Reproducing the analysis

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


## Data provenance

| Dataset | Source and collector | Licence | Cite as |
|---|---|---|---|
| Bird surveys (`birdata_raw.csv`, and the derived `surveys.csv`, `detections_long.csv`) | BirdLife Australia Birdata program; volunteer observers following the standard 2-ha 20-minute search protocol. Downloaded from the Atlas of Living Australia (data resource dr359) with the `galah` R package. | CC BY-NC 4.0 | BirdLife Australia (2026). Birdata. Accessed via the Atlas of Living Australia, https://collections.ala.org.au/public/show/dr359, 22nd, Oct 2026. |
| Fire extent (`data/fire/NIAFED_v20200623.*`) | **National Indicative Aggregated Fire Extent Dataset** v20200623, compiled by the Australian Government Department of Agriculture, Water and the Environment from state and territory fire-mapping data for the 2019–20 season. | CC BY 4.0 | DAWE (2020). National Indicative Aggregated Fire Extent Dataset, v20200623. Department of Agriculture, Water and the Environment, Canberra. |
| Poster figure (adapted) | Legge S. et al. (2022). Diversity and Distributions 28, 571–591. doi:10.1111/ddi.13428 | CC BY 4.0 | as given |

Other references cited on the poster: Godfree et al. (2021) *Nat. Commun.* 12, 1023; Driscoll et al. (2024) *Nature* 635; Daly et al. (2026) *Aust. Zool.* 45(3), AZ26005.

## Use of generative AI

- **Claude via Claude Code:** helped write codes, fit GLMM model. Language polish in readme.md
- The extended abstract, the poster text and all interpretations are my own.

## Licence

Code: see `LICENSE`. Data remain under their original licences (above).
