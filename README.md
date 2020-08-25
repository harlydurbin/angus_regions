# Exploring genotype-by-environment interactions in American Angus cattle

## Data import

Documented in `notebooks/import_regions.Rmd`

### Goals

* Import weaning weight (direct and maternal) and post-weaning gain breeding values 
* Import contemporary group solutions
* Match up "renamed" animal IDs to AAA registration numbers
* Assign records to to environmental regions
* Initial data filtration

### Resulting data

* `data/derived_data/growth_pheno.rds`: Convert "wide" formatted `renf90.dat` containing phenotypes, renumbered IDs, and renumbered CG numbers to "long" format
* `data/derived_data/animal_regions.rds`: direct and maternal weaning weight breeding values, direct post-weaning gain breeding values, actual weaning weights, associated regional metadata
  * Removed rows from outside continental U.S. 
  * Removed rows where `zip` does not reside inside `herd_state`
  * Remved rows with `zip` that do not assign to a `region`
  * Removed rows with no recorded weight `value`
  * Removed animals born via embryo transfer
  * Removed rows where `region == 8` but K31 fescue not actually found in `herd_state` (`herd_state %in% c("CA", "WA", "OR", "PA", "NY", "WI", "NJ", "MA", "MD", "DE", "MI", "CT", "RI", "NH", "NE") & region == 8`)
  * Remove rows where `region == 9` but `herd_state` not in Upper Midwest/Northeast (`herd_state %in% c("CA", "OR", "ID", "WA") & region == 9`)
  * Remove rows where `n_animals == 1` (single animal contemporary groups)
* `data/derived_data/cg_regions.rds`: direct and maternal weaning weight contemporary group solutions, direct post-weaning gain contemporary group solutions

## Exploratory analyses

* Summarize phenotypic differences as well as differences in breeding values & CG solutions resulting from NCE weekly growth run in `notebooks/regions_summary.Rmd`. Summarize the same data as function of time in `notebooks/trends_summary.Rmd`
* Summarize phenotypic variance in AI sire progeny across regions in `notebooks/progeny_variance.Rmd`
  * For AI sires with calves born in multiple regions, how much does the mean weaning weight of their calves vary from region to region? 
  * Is the difference in mean weaning weight of calves consistent between sires or do some sires show more variability across regions?
* `notebooks/genetic_trends.Rmd`
* ~~`notebooks/environmental_variance.Rmd`~~
* ~~`notebooks/weather.Rmd`~~

## Genetic correlations between regions

* Results summarized using `notebooks/ww_bivsum_template.Rmd`, `notebooks/pwg_bivsum_template.Rmd`, `notebooks/bivcorr_template.Rmd`, `notebooks/bivsire_template.Rmd`

## Misc.

* Model bias evaluation in `notebooks/bias_eval.Rmd`