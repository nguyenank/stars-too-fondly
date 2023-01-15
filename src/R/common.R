
colours <- list(
    nightsky = "#0b1026",
    link     = "#2b314a",
    star     = "#f5f0e5"
)

parse_args <- function() {
    args <- commandArgs(trailingOnly = TRUE)
    constellation <- args[1]

    if (!constellation_is_valid(constellation)) {
        message(str_glue("Constellation {constellation} has no match.json! Skipping."))
        quit(save="no", status=0)
    }

    constellation
}

constellation_is_valid <- function(constellation) {
    file.exists(here::here("data", "constellations", constellation, "match.json"))
}

aspect_ratio <- 100 / 85

theme_common <- function() {
    list(
        ggplot2::theme_void() +
        ggplot2::theme(
            panel.background = ggplot2::element_rect(fill = colours$nightsky, size = 0),
            plot.background  = ggplot2::element_rect(fill = colours$nightsky, size = 0),
            legend.position  = "none"
        )
    )
}

star_cols <- readr::cols(
    mag = readr::col_double(),
    ra = readr::col_double(),
    npd = readr::col_double(),
    dec = readr::col_double(),
    bayer = readr::col_character(),
    superscript = readr::col_character(),
    constellation = readr::col_character(),
    name = readr::col_character(),
    ra_radians = readr::col_double(),
    dec_radians = readr::col_double(),
    raw_x = readr::col_double(),
    raw_y = readr::col_double(),
    x = readr::col_double(),
    y = readr::col_double()
)

shot_cols <- readr::cols(
    id = readr::col_character(),
    game_id = readr::col_double(),
    team_id = readr::col_double(),
    team = readr::col_character(),
    game_label = readr::col_character(),
    kickoff = readr::col_datetime(),
    x = readr::col_double(),
    y = readr::col_double(),
    event_type = readr::col_character()
)
