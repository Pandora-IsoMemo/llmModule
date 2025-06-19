FROM ghcr.io/pandora-isomemo/base-image:latest

ADD . .

RUN installPackage

# Expose ports
EXPOSE 3838

CMD ["Rscript", "-e", "library(shiny); llmModule::startApplication(3838, host = '0.0.0.0')"]
