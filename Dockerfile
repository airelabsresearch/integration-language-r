FROM rocker/r-base:latest

# jsonlite is the only dependency — reads/writes JSON for the Hook I/O protocol
RUN Rscript -e "install.packages('jsonlite', repos='https://cloud.r-project.org')"

WORKDIR /app
COPY . .

# CMD (not ENTRYPOINT) so you can override with e.g.:
#   docker run amortize-r Rscript tests/test_model.R
CMD ["Rscript", "main.R"]
