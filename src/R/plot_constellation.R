suppressPackageStartupMessages(library(tidyverse))
source(here::here("src", "R", "common.R"))
library(sportyR)

constellation <- parse_args()
stars <- read_csv(here::here("data", "constellations", constellation, "stars_transformed.csv"), col_types = star_cols)
links <- read_csv(here::here("data", "constellations", constellation, "links_transformed.csv"), col_types = star_cols)

plot_stars <- function(stars, links) {
    geom_hockey(
      "NHL",
      display_range = "offense",
      rotation = 90,
      rink_updates = list(
        penalty_box_length = 0,
        penalty_box_depth = 0,
        penalty_box_separation = 0,
        bench_length = 0,
        bench_depth = 0
      ),
      color_updates = list(
        plot_background = colours$nightsky,
        ozone_ice = colours$nightsky,
        nzone_ice = colours$nightsky,
        boards = colours$nightsky,
        center_line = colours$nightsky,
        zone_line = colours$nightsky,
        goal_line = colours$nightsky,
        restricted_trapezoid = colours$nightsky,
        goal_crease_outline = colours$nightsky,
        goal_crease_fill = colours$nightsky,
        referee_crease = colours$nightsky,
        center_faceoff_spot = colours$nightsky,
        faceoff_spot_ring = colours$nightsky,
        faceoff_spot_stripe = colours$nightsky,
        center_faceoff_circle = colours$nightsky,
        odzone_faceoff_circle = colours$nightsky,
        faceoff_line = colours$nightsky,
        goal_frame = colours$nightsky,
        goal_fill = colours$nightsky,
        team_a_bench = colours$nightsky,
        team_b_bench = colours$nightsky,
        team_a_penalty_box = colours$nightsky,
        team_b_penalty_box = colours$nightsky,
        off_ice_officials_box = colours$nightsky
      )
    )+
    geom_path(
      data =   links %>%
        mutate(group = cumsum(weight != lag(weight, default = 0))),
      aes(group = group, x=x, y=y),
      colour = colours$link,
      lineend = "round",
      linewidth = 1.2
    ) +
    geom_point(
      aes(size = exp(mag), x =x , y=y),
      colour = colours$star,
      data = stars
    ) +
    scale_size_continuous(limits = c(0, exp(7)), range = c(2, 14)) +
    theme_common()
}

plot_stars(stars, links) %>%
  ggsave(
    here::here("public", constellation, "stars.png"),
    plot = .,
    width = 6,
    height = 6*aspect_ratio
  )
