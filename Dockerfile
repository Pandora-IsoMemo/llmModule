FROM inwt/r-shiny:4.4.3

RUN echo "options(repos = c(getOption('repos'), PANDORA = 'https://Pandora-IsoMemo.github.io/drat/'))" >> /usr/local/lib/R/etc/Rprofile.site


RUN Rscript -e "remotes::install_github('r-lib/httr2@v1.2.3')" \
    && Rscript -e "remotes::install_github('tidyverse/ellmer@v0.4.1')"

ADD . .

RUN apt-get update && apt-get install -y --no-install-recommends \
    libuv1-dev \
    pandoc \
    pkg-config \
 && rm -rf /var/lib/apt/lists/*

RUN installPackage

# Expose ports
EXPOSE 3838

CMD ["Rscript", "-e", "library(shiny); llmModule::startApplication(3838, host = '0.0.0.0')"]
