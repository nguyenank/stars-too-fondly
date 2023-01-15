suppressPackageStartupMessages(library(tidyverse))
library(sportyR)
source(here::here("src", "R", "common.R"))

constellation <- parse_args()
data <- read_csv(here::here("data", "constellations", constellation, "shots.csv"))

plot_shots <- function(data) {
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
      boards = colours$link,
      center_line = colours$link,
      zone_line = colours$link,
      goal_line = colours$link,
      restricted_trapezoid = colours$link,
      goal_crease_outline = colours$link,
      goal_crease_fill = colours$nightsky,
      referee_crease = colours$link,
      center_faceoff_spot = colours$link,
      faceoff_spot_ring = colours$link,
      faceoff_spot_stripe = colours$link,
      center_faceoff_circle = colours$link,
      odzone_faceoff_circle = colours$link,
      faceoff_line = colours$link,
      goal_frame = colours$link,
      goal_fill = colours$nightsky,
      team_a_bench = colours$nightsky,
      team_b_bench = colours$nightsky,
      team_a_penalty_box = colours$nightsky,
      team_b_penalty_box = colours$nightsky,
      off_ice_officials_box = colours$nightsky
    )
  ) + geom_point(
    data = data |> mutate(size = if_else(event_type == 'GOAL', 6, 5)),
    aes(x = x, y = y, size = size),
    color = colours$star,
    show.legend = FALSE
  ) + scale_size_identity() +
    theme_common()
}

plot_shots(data) %>%
  ggsave(here::here("public", constellation, "shots.png"),
    plot = .,
    width = 6,
    height = 6 * aspect_ratio
  )
