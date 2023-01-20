# Stars Too Fondly

Matching constellations to shot maps of Dallas Stars players.

Run `make all` to run the matching algorithm for all constellations and view the numerical results at `data/constellations/{constellation}/...` or the images at `public/{constellation}/...`, after making sure you've satisfied the **requirements** (listed below).

This code is heavily based on that of [Nebra Shot Maps](https://github.com/Torvaney/nebra-shot-maps), and this entire project was inspired by that one.

## Results

The full results are available to peruse on [this webpage](https://stars-too-fondly.netlify.app/).

## Requirements

-   A Python environment (assumed to be at `venv`, unless otherwise set with the `PYTHON_VENV` environment variable). Anything version 3.6+ should be fine. Required packages are in `requirements.txt`.
    -   You can create a virtual environment at `venv` and install the requirements with `make venv`
-   An R installation, with the [tidyverse](https://github.com/tidyverse/tidyverse) and [sportyR](https://github.com/sportsdataverse/sportyR) installed.
-   `data/shots.csv`. A csv with at least the columns `x`, `y`, `game_id` and `player_name`; the code I used for gathering this data is in `src/R/generate_data.R` and requires [fastRhockey](https://github.com/sportsdataverse/fastRhockey) in addition to the other R package requirements.

## Name

The name for this project comes from the poem "The Old Astronomer to his Pupil" by Sarah Williams (editorialized by Hazel Felleman).
