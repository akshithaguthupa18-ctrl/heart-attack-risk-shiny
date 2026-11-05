# CDC BRFSS 2023 dataset

Source: [CDC 2023 annual data and documentation](https://www.cdc.gov/brfss/annual_data/annual_2023.html).
Direct download: https://www.cdc.gov/brfss/annual_data/2023/files/LLCP2023XPT.zip

BRFSS is a telephone survey of noninstitutionalized adults. This public-use file contains **433,323 real responses**, not synthetic or duplicated rows, and 345 variables. It covers 48 states, Washington DC, Guam, Puerto Rico and the US Virgin Islands. Kentucky and Pennsylvania did not meet inclusion requirements in 2023. The source page documents revisions; `provenance.json` records the downloaded archive checksum. The original XPT is approximately 1.2 GB; the repository includes a ten-column extract with all 433,323 rows, rather than the very large original transport file.

## Fields retained

| Raw field | Meaning | Analysis handling |
|---|---|---|
| CVDINFR4 | Ever told of a heart attack / myocardial infarction | Target: 1=yes, 2=no; unknown/refused/missing excluded |
| _AGEG5YR | Age category | 1–13, from 18–24 through 80+; 14=missing |
| SEXVAR | Survey sex | 1=male; 2=female |
| _BMI5 | BMI × 100 | Divide by 100; restrict to 12–80 for this analysis |
| BPHIGH6 | High blood pressure diagnosis | 1=yes; 2=pregnancy only, 3=no, 4=borderline treated as no |
| TOLDHI3 | Told cholesterol high | 1=yes; 2=no |
| DIABETE4 | Diabetes diagnosis | 1=yes; 2=pregnancy only, 3=no, 4=prediabetes treated as no |
| _SMOKER3 | Four-level smoking status | 1/2=current; 3/4=not current |
| EXERANY2 | Leisure-time exercise in past month | 1=active; 2=inactive |
| _LLCPWT | Final survey weight | Retained, not used by the unweighted baseline model |

All other codes in the predictors become missing. Predictor imputation uses medians computed from training data only. These recodings simplify the original responses; they are project choices, not clinical definitions.

## Counts and quality

- Known outcomes: **430,755**. Unknown outcomes excluded: **2,568**.
- Training: **258,452**; validation: **86,150**; test: **86,153**.
- Missing predictors among known outcomes: age 7,561; sex 0; BMI 40,084; blood pressure 1,714; cholesterol 54,357; diabetes 750; smoking 22,707; physical activity 1,166.
- `missingness.csv` includes exact training medians. `test_predictions.csv` includes actual held-out labels and probabilities.

These are self-reported, cross-sectional survey responses. The target is a *past diagnosis*, not future incidence. Recall bias, nonresponse, survivorship, post-diagnosis behavior, imputation and population differences limit interpretation. Unweighted sample summaries are not national population estimates. Proper population inference needs the complex survey design as well as weights; keeping `_LLCPWT` alone does not establish survey-correct inference.

CDC public-use data are attributed to CDC. The project's MIT license applies to original code and documentation; it does not relicense third-party runtime assets. No endorsement by CDC is implied.
