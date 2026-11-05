# Reproducible modelling: run from the project directory with Rscript analysis.R
set.seed(20261105)
raw <- read.csv('brfss_selected.csv', check.names=FALSE)
valid <- function(x, values) ifelse(x %in% values, x, NA_real_)
binary <- function(x) ifelse(x %in% c(1,2), as.integer(x == 1), NA_real_)
d <- data.frame(
  heart_attack=binary(raw$CVDINFR4),
  age=valid(raw$`_AGEG5YR`,1:13),
  male=ifelse(raw$SEXVAR %in% 1:2,as.integer(raw$SEXVAR==1),NA),
  bmi=raw$`_BMI5`/100,
  hypertension=ifelse(raw$BPHIGH6 %in% 1:4,as.integer(raw$BPHIGH6==1),NA),
  cholesterol=binary(raw$TOLDHI3),
  diabetes=ifelse(raw$DIABETE4 %in% 1:4,as.integer(raw$DIABETE4==1),NA),
  smoker=ifelse(raw$`_SMOKER3` %in% 1:4,as.integer(raw$`_SMOKER3` %in% 1:2),NA),
  inactive=ifelse(raw$EXERANY2 %in% 1:2,as.integer(raw$EXERANY2==2),NA),
  weight=raw$`_LLCPWT`)
d$bmi[d$bmi<12 | d$bmi>80] <- NA
d <- d[!is.na(d$heart_attack),]
# Stratified 60/20/20 train / validation / test. Imputation uses training only.
split <- integer(nrow(d))
for (y in 0:1) {
  ix <- sample(which(d$heart_attack==y)); n <- length(ix)
  split[ix] <- c(rep(1,floor(.6*n)),rep(2,floor(.2*n)),rep(3,n-floor(.6*n)-floor(.2*n)))
}
features <- c('age','male','bmi','hypertension','cholesterol','diabetes','smoker','inactive')
medians <- sapply(d[split==1,features],median,na.rm=TRUE)
missing <- sapply(d[features],function(x) sum(is.na(x)))
for (f in features) d[[f]][is.na(d[[f]])] <- medians[[f]]
train <- d[split==1,]; validation <- d[split==2,]; test <- d[split==3,]
formula <- heart_attack ~ age + I(age^2) + male + bmi + I(bmi^2) + hypertension + cholesterol + diabetes + smoker + inactive
model <- glm(formula, data=train, family=binomial())
pv <- predict(model,validation,type='response')
# Select Youden threshold ONLY on validation; held-out test remains untouched.
candidates <- seq(.01,.50,by=.005)
score <- sapply(candidates,function(t) mean(pv[validation$heart_attack==1]>=t)+mean(pv[validation$heart_attack==0]<t)-1)
threshold <- candidates[which.max(score)]
p <- as.numeric(predict(model,test,type='response')); y <- test$heart_attack
auc <- function(y,p) {n1<-sum(y==1); n0<-sum(y==0); (sum(rank(p)[y==1])-n1*(n1+1)/2)/(n1*n0)}
metric <- function(y,p,t) {
  tp<-sum(y==1&p>=t); fp<-sum(y==0&p>=t); tn<-sum(y==0&p<t); fn<-sum(y==1&p<t)
  c(AUC=auc(y,p),Brier=mean((p-y)^2),Accuracy=(tp+tn)/length(y),Sensitivity=tp/(tp+fn),Specificity=tn/(tn+fp),Precision=tp/(tp+fp),TP=tp,FP=fp,TN=tn,FN=fn)
}
metrics <- metric(y,p,threshold)
baseline <- mean(train$heart_attack)
roc <- do.call(rbind,lapply(c(Inf,seq(.999,0,length.out=300),-Inf),function(t) c(fpr=mean(p[y==0]>=t),tpr=mean(p[y==1]>=t))))
bin <- pmin(10,ceiling(rank(p,ties.method='first')/length(p)*10))
calibration <- aggregate(cbind(predicted=p,observed=y),list(decile=bin),mean)
groups <- lapply(c('male','age'),function(f) {
  z<-do.call(rbind,lapply(sort(unique(test[[f]])),function(v) {i<-test[[f]]==v; data.frame(group=f,value=v,n=sum(i),prevalence=mean(y[i]),auc=if(length(unique(y[i]))==2)auc(y[i],p[i]) else NA)})); z
})
age_summary <- aggregate(cbind(count=rep(1,nrow(d)),positive=d$heart_attack),list(age=d$age),sum)
age_summary$rate <- age_summary$positive/age_summary$count
effects <- data.frame(term=names(coef(model)),coefficient=unname(coef(model)),odds_ratio=exp(unname(coef(model))))
compact_model <- model[c('coefficients','rank','family','terms','xlevels','contrasts','call','qr','df.residual')]
compact_model$qr$qr <- model$qr$qr[seq_len(model$rank),,drop=FALSE]
class(compact_model) <- class(model)
stopifnot(isTRUE(all.equal(as.numeric(predict(compact_model,test,type='response')),p)))
bundle <- list(model=compact_model,threshold=threshold,medians=medians,metrics=metrics,baseline=baseline,
  baseline_brier=mean((baseline-y)^2),raw_rows=nrow(raw),n=nrow(d),excluded=nrow(raw)-nrow(d),
  train=nrow(train),validation=nrow(validation),test=nrow(test),prevalence=mean(d$heart_attack),
  missing=missing,roc=roc,calibration=calibration,groups=do.call(rbind,groups),age_summary=age_summary,effects=effects,
  data=d,split=split)
saveRDS(bundle,'bundle.rds',compress='xz')
write.csv(data.frame(metric=names(metrics),value=unname(metrics)),'metrics.csv',row.names=FALSE)
write.csv(effects,'coefficients.csv',row.names=FALSE)
write.csv(bundle$groups,'subgroup_metrics.csv',row.names=FALSE)
write.csv(data.frame(feature=names(missing),missing=unname(missing),training_median=medians),'missingness.csv',row.names=FALSE)
write.csv(data.frame(actual=y,probability=p),'test_predictions.csv',row.names=FALSE)
writeLines(c('# Analysis results',sprintf('Raw responses: %s; known outcomes: %s; excluded unknown outcomes: %s.',nrow(raw),nrow(d),bundle$excluded),
 sprintf('Train: %s; validation: %s; test: %s.',nrow(train),nrow(validation),nrow(test)),
 sprintf('Test ROC AUC: %.4f. Brier: %.4f (constant baseline %.4f).',metrics['AUC'],metrics['Brier'],bundle$baseline_brier),
 sprintf('Validation-selected threshold: %.3f. Test sensitivity %.3f; specificity %.3f; precision %.3f.',threshold,metrics['Sensitivity'],metrics['Specificity'],metrics['Precision']),
 'Unweighted research classifier of self-reported heart attack HISTORY. No future time horizon, causality, diagnostic or clinical validation is established.',
 'BRFSS is a complex survey; these unweighted model and sample summaries are not US population prevalence estimates. Missing predictors were median-imputed using training data only. Age is an ordered five-year category (13 = 80+), not exact age.',
 'Random within-year splitting is internal validation only. External/temporal validation, survey-design analysis, and clinical evaluation are required before any practical use.'),'RESULTS.md')
print(metrics); print(c(raw=nrow(raw),known=nrow(d),train=nrow(train),validation=nrow(validation),test=nrow(test),threshold=threshold))
