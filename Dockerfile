FROM ghcr.io/pandora-isomemo/base-image:latest

ADD . .

RUN installPackage
