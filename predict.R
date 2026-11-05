# Usage: Rscript predict.R profiles.csv predictions.csv
# Input columns: age (category 1:13), male (0/1), bmi (12:80),
# hypertension, cholesterol, diabetes, smoker, inactive (all 0/1).
args <- commandArgs(trailingOnly=TRUE)
if(length(args)!=2) stop('Usage: Rscript predict.R profiles.csv predictions.csv')
b <- readRDS('bundle.rds'); d <- read.csv(args[1])
fields <- names(b$medians)
if(!all(fields %in% names(d))) stop(paste('Required columns:',paste(fields,collapse=', ')))
for(f in fields) {
 if(!is.numeric(d[[f]])) stop(paste(f,'must be numeric'))
 if(any(!is.finite(d[[f]]) & !is.na(d[[f]]))) stop('Infinite values are invalid')
 d[[f]][is.na(d[[f]])] <- b$medians[[f]]
}
stopifnot(all(d$age %in% 1:13),all(d$bmi>=12 & d$bmi<=80))
for(f in setdiff(fields,c('age','bmi'))) stopifnot(all(d[[f]] %in% 0:1))
d$history_probability <- as.numeric(predict(b$model,d,type='response'))
d$class_at_research_threshold <- as.integer(d$history_probability>=b$threshold)
d$interpretation <- 'Self-reported heart attack history association; not future risk'
write.csv(d,args[2],row.names=FALSE)
