# CardioScope · Heart attack history prediction with R Shiny

An interactive, reproducible research project built on **433,323 CDC BRFSS 2023 survey responses**.

The Shiny app can run locally or be published with the included GitHub Pages workflow. Upstream: https://github.com/akshithaguthupa18-ctrl/heart-attack-risk-shiny · Contributor fork: https://github.com/Zeeshan1786/heart-attack-risk-shiny

The main view preserves the health-input form and adds four reactive profile charts (age, BMI, fitted-term contributions and survey context). The app also contains a working prediction form, dataset explorer, missingness and variable dictionary, ROC and calibration plots, confusion matrix, subgroup evaluation and downloadable results. R and Shiny run in your browser through Shinylive/webR; the first load downloads the R runtime and can take a little time.

> The prediction estimates association with **self-reported history of heart attack**. It is an educational classifier, not a validated forecast of a future heart attack, diagnostic tool, or treatment guide.

## Run locally

Install R 4.4+ and run from this directory:

```r
install.packages('shiny', repos='https://cloud.r-project.org')
shiny::runApp('.', launch.browser=TRUE)
```

The included `bundle.rds` contains the fitted model and analysis data, so retraining is not needed to launch the app.

## Reproduce analysis

```r
# brfss_selected.csv already contains all rows of the ten selected source fields.
source('analysis.R')
source('tests.R')
# Optional: download the original CDC XPT and regenerate the extract:
# source('prepare_data.R')
```

The original pipeline was executed in R 4.6.0 through webR. The CSV transport extract was made with pyreadstat; `prepare_data.R` provides an R-only alternative. Statistical preprocessing, splitting, fitting, evaluation and predictions all use R.

## Model and results

Logistic regression with eight predictors and quadratic age-category and BMI terms; seeded stratified 60/20/20 split; training-only median imputation; threshold selected on validation, followed by untouched test evaluation.

| Held-out test metric | Result |
|---|---:|
| Responses | 86,153 |
| ROC AUC | 0.8042 |
| Brier score | 0.0477 |
| Constant-prevalence Brier baseline | 0.0515 |
| Sensitivity | 81.4% |
| Specificity | 65.9% |
| Precision | 12.1% |
| Accuracy | 66.7% |
| Validation-selected threshold | 0.050 |

The low precision is important: most positive classifications at this threshold are false positives. The threshold balances sensitivity and specificity statistically; it is not a clinical cutoff. Internal discrimination does not establish clinical utility or generalization.

## Files

| File | Purpose |
|---|---|
| app.R | Shiny frontend and reactive prediction server |
| analysis.R | Complete R preprocessing, fit and evaluation |
| prepare_data.R | Optional R-only source-data download |
| predict.R | Batch CSV prediction command-line interface |
| tests.R | Model integrity and profile prediction checks |
| brfss_selected.csv | All 433,323 rows, ten source columns |
| bundle.rds | Compact fitted model, imputation medians, metrics, analysis data |
| DATASET.md / provenance.json | Dataset definitions, limitations and checksum |
| RESULTS.md / metrics.csv | Evaluation results |
| coefficients.csv / subgroup_metrics.csv / missingness.csv | Auditable analysis artifacts |
| test_predictions.csv | Held-out outcomes and predicted probabilities |
| .github/workflows/pages.yml | Automated model checks, Shinylive build and Pages deployment |
| Dockerfile | Conventional server-hosted R Shiny deployment |
| export.R | Regenerate the static Shinylive build |

## Deployment and development

The included GitHub Actions workflow tests the model, builds the browser app from `app.R` and `bundle.rds`, and deploys to Pages. In repository Settings > Pages, choose GitHub Actions. For local static serving, run `source('export.R')` and serve the generated `docs/` folder. Generated runtime assets are build artifacts. All frontend, modelling and data files are independently editable. See [DATASET.md](DATASET.md) and [RESULTS.md](RESULTS.md) for details.

For conventional Shiny hosting, deploy this directory to shinyapps.io or Posit Connect, or use `docker build -t cardioscope .` and `docker run --rm -p 3838:3838 cardioscope`.

No personal health data is collected or stored by the application. Profile entries live only in the browser session (or Shiny session when server-hosted). Third-party fonts and runtime dependencies may be fetched during loading.
