# Optional full R data acquisition. Requires haven; selected CSV is already included.
if (!requireNamespace('haven',quietly=TRUE)) install.packages('haven',repos='https://cloud.r-project.org')
dir.create('raw',showWarnings=FALSE)
url <- 'https://www.cdc.gov/brfss/annual_data/2023/files/LLCP2023XPT.zip'
download.file(url,'raw/LLCP2023XPT.zip',mode='wb')
unzip('raw/LLCP2023XPT.zip',exdir='raw')
file <- list.files('raw',pattern='XPT',full.names=TRUE,ignore.case=TRUE)
file <- file[!grepl('zip$',file,ignore.case=TRUE)][1]
columns <- c('CVDINFR4','_AGEG5YR','SEXVAR','_BMI5','BPHIGH6','TOLDHI3','DIABETE4','_SMOKER3','EXERANY2','_LLCPWT')
data <- haven::read_xpt(file,col_select=tidyselect::all_of(columns))
stopifnot(nrow(data)>400000,all(columns %in% names(data)))
write.csv(as.data.frame(data),'brfss_selected.csv',row.names=FALSE,na='')
cat(nrow(data),'responses saved. Run source("analysis.R") next.\n')
