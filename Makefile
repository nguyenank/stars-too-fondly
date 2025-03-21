PYTHON_VENV ?= venv
SIMILARITY_FUNCTION ?= euclidean

CONSTELLATIONS = $(shell ls data/*/)


.PHONY: all
all: data
	@$(MAKE) $(patsubst %,data/constellations/%/match.json,$(CONSTELLATIONS))
	@$(PYTHON_VENV)/bin/python src/python/make_json.py data/constellations/ data/constellations.json
# MATCHING

data/constellations/%/match.json: data/constellations/%/stars.csv
	@$(PYTHON_VENV)/bin/python src/python/match_constellation.py \
		data/shots.csv \
		data/constellations/$* \
		--similarity $(SIMILARITY_FUNCTION)
	@Rscript src/R/plot_constellation.R $*
	@Rscript src/R/plot_shots.R $*

# Stars rule performs the matching and generates images, too
public/%/stars.png: data/constellations/%/match.json

public/%/shots.png: data/constellations/%/match.json



# DATA

.PHONY: data
data: data/shots.csv data/SnT_constellations.txt data/constellation_names.eng.fab data/constellations

# Fetch from db
data/shots.csv:
	@if [ ! -f data/shots.csv ]; then \
		echo "You need to add a 'shots.csv' file to the 'data' folder!"; \
		exit 1; \
	fi


# Creates links and stars for each constellation (using the directory to inform
# make of how up-to-date they are)
data/constellations: data/SnT_constellations.txt data/constellation_names.eng.fab
	mkdir -p data/constellations/
	$(PYTHON_VENV)/bin/python src/python/parse_constellations.py \
		data/SnT_constellations.txt \
		data/constellation_names.eng.fab \
		data/constellations/ \
		public/
	touch data/constellations

data/constellations/%/stars.csv: data/constellations

data/constellations/%/links.csv: data/constellations


data/SnT_constellations.txt:
	wget \
		https://raw.githubusercontent.com/Stellarium/stellarium/43d4dba4c85d3264244faad27cf1f60ddf92083c/skycultures/western_SnT/SnT_constellations.txt \
		-O data/SnT_constellations.txt

data/constellation_names.eng.fab:
	wget \
		https://raw.githubusercontent.com/Stellarium/stellarium/43d4dba4c85d3264244faad27cf1f60ddf92083c/skycultures/western_SnT/constellation_names.eng.fab \
		-O data/constellation_names.eng.fab



# DEV

.PHONY: clean
clean:
	rm -f  data/SnT_constellations.txt data/constellation_names.eng.fab
	rm -rf data/constellations/*
	rm -rf public/*


.PHONY: env
env:
	python -m venv $(PYTHON_VENV)
	$(PYTHON_VENV)/bin/pip install --upgrade pip
	$(PYTHON_VENV)/bin/pip install -r requirements.txt
	@echo "TODO: renv"


.PHONY: test
test:
	$(PYTHON_VENV)/bin/pytest
