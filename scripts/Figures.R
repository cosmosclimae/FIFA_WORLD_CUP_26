# =========================================================
# Figure 1 - Tournament structure and local kick-off times
# Final full version
# =========================================================

library(tidyverse)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(patchwork)
library(scales)

# ---------------------------------------------------------
# 1) Stadium coordinates
# ---------------------------------------------------------
stadiums <- tribble(
  ~stadium, ~lat, ~lon,
  "bc_place", 49.276667, -123.111944,
  "arrowhead_stadium", 39.048889, -94.483889,
  "bmo_field", 43.632778, -79.418611,
  "gillette_stadium", 42.091111, -71.264444,
  "metlife_stadium", 40.813611, -74.074444,
  "lincoln_financial_field", 39.900833, -75.167500,
  "lumen_field", 47.595278, -122.331667,
  "levis_stadium", 37.403056, -121.970000,
  "mercedes_benz_stadium", 33.755000, -84.401111,
  "hard_rock_stadium", 25.958056, -80.238889,
  "sofi_stadium", 33.953333, -118.339167,
  "estadio_akron", 20.681667, -103.462778,
  "bbva_stadium", 25.670278, -100.243611,
  "estadio_azteca", 19.302778, -99.150556,
  "att_stadium", 32.747778, -97.092778,
  "nrg_stadium", 29.684722, -95.410833
)

# ---------------------------------------------------------
# 2) Read match schedule
# ---------------------------------------------------------
# Replace with your real file path if needed
matches <- read_csv("fifa2026_matches.csv", show_col_types = FALSE)

# Expected columns:
# stadium, city, venue_name, kickoff_hour_local, phase, phase_order, match_date_local

# ---------------------------------------------------------
# 3) Aggregate stadium information
# ---------------------------------------------------------
stadium_summary <- matches %>%
  group_by(stadium) %>%
  summarise(
    n_matches = n(),
    city = first(city),
    venue_name = first(venue_name),
    .groups = "drop"
  ) %>%
  left_join(stadiums, by = "stadium") %>%
  mutate(
    city_label = case_when(
      city == "San Francisco Bay Area" ~ "San Francisco",
      city == "New York New Jersey" ~ "New York",
      TRUE ~ city
    ),
    country = case_when(
      stadium %in% c("bc_place", "bmo_field") ~ "Canada",
      stadium %in% c("estadio_akron", "bbva_stadium", "estadio_azteca") ~ "Mexico",
      TRUE ~ "USA"
    )
  )

# ---------------------------------------------------------
# 4) Base map
# ---------------------------------------------------------
world <- ne_countries(scale = "medium", returnclass = "sf")

na_map <- world %>%
  filter(admin %in% c("United States of America", "Canada", "Mexico"))

bbox <- st_bbox(c(
  xmin = -128,
  xmax = -66,
  ymin = 17,
  ymax = 52
), crs = st_crs(4326))

na_map_crop <- st_crop(na_map, bbox)

# ---------------------------------------------------------
# 5) Manual label positions
# ---------------------------------------------------------
label_positions <- stadium_summary %>%
  mutate(
    label_x = case_when(
      city_label == "Vancouver"      ~ lon + 1.4,
      city_label == "Seattle"        ~ lon + 1.2,
      city_label == "San Francisco"  ~ lon - 1.0,
      city_label == "Los Angeles"    ~ lon - 1.6,
      city_label == "Kansas City"    ~ lon + 0.2,
      city_label == "Dallas"         ~ lon - 1.2,
      city_label == "Houston"        ~ lon - 1.0,
      city_label == "Monterrey"      ~ lon - 0.8,
      city_label == "Guadalajara"    ~ lon - 0.8,
      city_label == "Mexico City"    ~ lon + 1.1,
      city_label == "Miami"          ~ lon - 0.4,
      city_label == "Atlanta"        ~ lon + 0.5,
      city_label == "Toronto"        ~ lon + 1.0,
      city_label == "Philadelphia"   ~ lon - 1.6,
      city_label == "New York"       ~ lon + 1.3,
      city_label == "Boston"         ~ lon + 1.7,
      TRUE ~ lon + 0.8
    ),
    label_y = case_when(
      city_label == "Vancouver"      ~ lat + 0.7,
      city_label == "Seattle"        ~ lat + 0.5,
      city_label == "San Francisco"  ~ lat - 1.0,
      city_label == "Los Angeles"    ~ lat - 1.2,
      city_label == "Kansas City"    ~ lat + 0.8,
      city_label == "Dallas"         ~ lat - 1.0,
      city_label == "Houston"        ~ lat - 1.0,
      city_label == "Monterrey"      ~ lat - 0.7,
      city_label == "Guadalajara"    ~ lat + 0.8,
      city_label == "Mexico City"    ~ lat - 0.8,
      city_label == "Miami"          ~ lat - 0.8,
      city_label == "Atlanta"        ~ lat + 0.7,
      city_label == "Toronto"        ~ lat + 0.7,
      city_label == "Philadelphia"   ~ lat - 0.3,
      city_label == "New York"       ~ lat + 0.1,
      city_label == "Boston"         ~ lat + 0.6,
      TRUE ~ lat + 0.4
    ),
    hjust = case_when(
      city_label %in% c("San Francisco", "Los Angeles", "Dallas", "Houston",
                        "Monterrey", "Guadalajara", "Philadelphia", "Miami") ~ 1,
      TRUE ~ 0
    )
  )

# ---------------------------------------------------------
# 6) Map panel
# ---------------------------------------------------------
country_cols <- c(
  "Canada" = "#2C7FB8",
  "Mexico" = "#E67E22",
  "USA"    = "#595959"
)

p_map <- ggplot() +
  geom_sf(
    data = na_map_crop,
    fill = "grey97",
    color = "grey70",
    linewidth = 0.35
  ) +
  geom_point(
    data = stadium_summary,
    aes(x = lon, y = lat, size = n_matches, fill = country),
    shape = 21,
    color = "black",
    stroke = 0.55,
    alpha = 0.95
  ) +
  geom_segment(
    data = label_positions,
    aes(x = lon, y = lat, xend = label_x, yend = label_y),
    color = "grey35",
    linewidth = 0.25
  ) +
  geom_text(
    data = label_positions,
    aes(x = label_x, y = label_y, label = city_label, hjust = hjust),
    size = 3.4
  ) +
  scale_fill_manual(values = country_cols, name = "Country") +
  scale_size_continuous(
    name = "Number of matches",
    range = c(3.5, 9),
    breaks = c(4, 5, 6, 7, 8, 9)
  ) +
  coord_sf(
    xlim = c(-128.5, -65.0),
    ylim = c(17, 52),
    expand = FALSE,
    clip = "off"
  ) +
  labs(
    title = "Host stadiums of the 2026 FIFA World Cup"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    panel.grid.major = element_line(color = "grey90", linewidth = 0.25),
    panel.grid.minor = element_blank(),
    axis.title = element_blank(),
    axis.text = element_text(color = "grey30"),
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    legend.box = "vertical",
    legend.title = element_text(face = "plain"),
    plot.margin = margin(t = 5.5, r = 20, b = 5.5, l = 20)
  ) +
  guides(
    fill = guide_legend(order = 1, override.aes = list(size = 4)),
    size = guide_legend(order = 2)
  )
# ---------------------------------------------------------
# 7) Kick-off panel (aggregate to full hours)
# ---------------------------------------------------------
matches_kickoff <- matches %>%
  mutate(
    kickoff_hour_local = as.numeric(kickoff_hour_local),
    kickoff_hour_bin = floor(kickoff_hour_local),
    kickoff_label = sprintf("%02d:00", kickoff_hour_bin)
  )

kickoff_levels <- matches_kickoff %>%
  distinct(kickoff_hour_bin, kickoff_label) %>%
  arrange(kickoff_hour_bin) %>%
  pull(kickoff_label)

matches_kickoff <- matches_kickoff %>%
  mutate(kickoff_label = factor(kickoff_label, levels = kickoff_levels))

p_kickoff <- ggplot(matches_kickoff, aes(x = kickoff_label)) +
  geom_bar(fill = "grey35", color = "black", linewidth = 0.25) +
  labs(
    title = "Distribution of local kick-off times",
    x = "Local kick-off hour",
    y = "Number of matches"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 12.5),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.minor = element_blank()
  )

# ---------------------------------------------------------
# 8) Tournament phase timeline
# ---------------------------------------------------------
phase_timeline <- matches %>%
  mutate(match_date_local = as.Date(match_date_local)) %>%
  group_by(phase_order, phase) %>%
  summarise(
    start_date = min(match_date_local),
    end_date   = max(match_date_local),
    .groups = "drop"
  ) %>%
  arrange(phase_order) %>%
  mutate(
    phase_label = recode(
      phase,
      "pool" = "Group stage",
      "round_of_32" = "Round of 32",
      "round_of_16" = "Round of 16",
      "quarter_final" = "Quarter-finals",
      "semi_final" = "Semi-finals",
      "bronze_final" = "Bronze final",
      "final" = "Final"
    ),
    phase_label = factor(phase_label, levels = rev(phase_label))
  )

p_phase <- ggplot(phase_timeline) +
  geom_segment(
    aes(
      x = start_date,
      xend = end_date,
      y = phase_label,
      yend = phase_label
    ),
    linewidth = 5,
    color = "grey55",
    lineend = "round"
  ) +
  geom_point(
    aes(x = start_date, y = phase_label),
    size = 2.2,
    color = "black"
  ) +
  geom_point(
    aes(x = end_date, y = phase_label),
    size = 2.2,
    color = "black"
  ) +
  labs(
    title = "Tournament calendar by phase",
    x = NULL,
    y = NULL
  ) +
  scale_x_date(
    date_labels = "%d %b",
    breaks = pretty_breaks(n = 6)
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 12.5),
    panel.grid.minor = element_blank()
  )

# ---------------------------------------------------------
# 9) Assemble final figure
# ---------------------------------------------------------
right_panel <- p_kickoff / p_phase + plot_layout(heights = c(1.12, 1))
fig1 <- p_map | right_panel + plot_layout(widths = c(1.85, 1))

# ---------------------------------------------------------
# 10) Print and save
# ---------------------------------------------------------
fig1

ggsave(
  filename = "figure1_tournament_structure_final_v2.png",
  plot = fig1,
  width = 14,
  height = 8,
  dpi = 300
)