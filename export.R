if(!requireNamespace('shinylive',quietly=TRUE)) install.packages('shinylive',repos='https://cloud.r-project.org')
stage <- tempfile('cardioscope-'); dir.create(stage)
file.copy(c('app.R','bundle.rds'),stage)
shinylive::export(stage,'docs',template_params=list(title='CardioScope | R Shiny'))
