FROM ghcr.io/pandora-isomemo/base-image:latest

ADD . .

# Install ollamar from GitHub
RUN Rscript -e "remotes::install_github('hauselin/ollama-r')"

RUN installPackage

# Expose ports
EXPOSE 3838

CMD ["Rscript", "-e", "library(shiny); llmModule::startApplication(3838, host = '0.0.0.0')"]
