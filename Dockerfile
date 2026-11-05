FROM rocker/shiny:4.5.2
WORKDIR /srv/shiny-server/cardioscope
COPY app.R bundle.rds ./
EXPOSE 3838
CMD ["R", "-e", "shiny::runApp('.', host='0.0.0.0', port=3838)"]
