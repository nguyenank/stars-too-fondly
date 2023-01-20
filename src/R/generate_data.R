suppressPackageStartupMessages(library(tidyverse))
source(here::here("src", "R", "common.R"))
library(fastRhockey)
library(lubridate)
library(sportyR)

all_shots <- tibble()

for (season in 2011:2023) {
  pbp <- load_nhl_pbp(season)

  shots <- pbp |>
    filter(
      event_type %in% c("SHOT", "MISSED_SHOT", "GOAL")
    ) |>
    filter(
      event_team == "Dallas Stars"
    )
  all_shots <- bind_rows(all_shots, shots)
}

# write.csv(all_shots, paste0("data/all_shots_raw-",Sys.Date(),".csv"), row.names=FALSE)

# all_shots <- read.csv("data/all_shots_raw-2023-01-06.csv")

clean_name <- function(name) {
  str_replace_all(name, "\\.", " ")
}

cleaned_shots <- all_shots |> select( event_type,
  game_id, season, season_type, home_name,
  home_final, away_final, date = date_time,
  away_name, x = x_fixed, y = y_fixed,
  player_name = event_player_1_name
) |> mutate(
  x = if_else(home_name == 'Dallas Stars', x, as.integer( -1 * x)),
  y = if_else(home_name == 'Dallas Stars', y , as.integer(-1 * y)),
  player_name = clean_name(player_name),
  date = with_tz(ymd_hms(date, tz ="UTC"), 'US/Pacific'),
  date = format(date(with_tz(date, "US/Pacific")), "%B %d, %Y")
) |> drop_na(x,y) |> rotate_coords(90)

write.csv(cleaned_shots, paste0("data/shots.csv"), row.names=FALSE)
