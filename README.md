# Exploring genotype-by-environment interactions in American Angus cattle

## Data import

Documented in `notebooks/import_regions.Rmd`

### Resulting data

* `data/derived_data/import_regions/animal_regions.rds`: direct and maternal weaning weight breeding values, actual weaning weights, associated regional metadata
* `data/derived_data/import_regions/cg_regions.rds`: weaning weight contemporary group solutions

#### Geographic QC & filtration

Removed:

* Rows from outside continental U.S. 
* Rows where `zip` does not reside inside `herd_state`
* Rows with `zip` that do not assign to a `region`
* Regions 4 & 6
* Rows where `region == 8` but K31 fescue not actually found in `herd_state` (`herd_state %in% c("CA", "WA", "OR", "PA", "NY", "WI", "NJ", "MA", "MD", "DE", "MI", "CT", "RI", "NH", "NE") & region == 8`)
* Rows where `region == 9` but `herd_state` not in Upper Midwest/Northeast (`herd_state %in% c("CA", "OR", "ID", "WA") & region == 9`)

#### Other QC & filtration

* Converted weights, EBVs, and contemporary group solutions from lbs. to kg.

Removed:

* Rows with no recorded weight
* Rows prior to 1990
* Creep-fed calves
* Calves born via embryo transfer
* Single-sire and single-dam contemporary groups
* Records from calves with unknown parentage

Then after filtration, removed:

* Contemporary groups with fewer than 5 animals
* Contemporary groups containing phenotypic outliers (weights 3 SD +/- national mean)

## Exploratory analyses

* Summarize phenotypic differences as well as differences in breeding values & CG solutions resulting from NCE weekly growth run in `notebooks/regions_summary.Rmd`
  * ~~Summarize the same data as function of time in `notebooks/trends_summary.Rmd`~~
* Summarize phenotypic variance in AI sire progeny across regions in `notebooks/progeny_variance.Rmd`
* ~~`notebooks/genetic_trends.Rmd`~~
* ~~`notebooks/environmental_variance.Rmd`~~
* ~~`notebooks/weather.Rmd`~~

## Genetic correlations between regions

### Data sampling

* In `source_functions/setup.gibbs_varcomp.R`
* Remove records from dams with calves in both the High Plains and one of the other regions (to avoid between-region MPE covariance issues)
* For 5 separate iterations, sample 50,000 +/- 500 records by zip code from the High Plains and each of the 6 other comparison ecoregions

### Variance components estimation

* BLUPF90 Gibbs sampling ran in `source_functions/gibbs_varcomp.snakefile`
  * 1,000,000 total samples with burn in of 50,000 samples and every 100th sample retained
* Post-Gibbs analysis ran in `source_functions/post_gibbs.snakefile` and evaluated in `notebooks/post_gibbs.Rmd`
* Variance component estimation results in `notebooks/gibbs_varcomp.Rmd`

## GWAS

* For each comparison region, extract 
