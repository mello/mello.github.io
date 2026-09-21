# ---------------------------------------------------------------------------
# office_map.R — builds the "finding my office" map for the Contact page.
#
# Produces a two-panel figure in the classic inset style:
#   - OUTER panel: Dartmouth's campus core, with Rockefeller highlighted and a
#     rectangle marking the area the inset blows up.
#   - INSET panel: Rockefeller and Silsby side by side, both labelled, with the
#     office marked.
#
# The point of the inset is the thing students actually get wrong: Rockefeller
# and Silsby read as one building from outside but are mapped, signed, and
# numbered separately. Showing both footprints together is what makes that
# legible.
#
# Run this by hand when the map needs changing; it is NOT part of the Quarto
# render, so the site never depends on R or on network access. It writes a PNG
# into site-schmitt/images/ and that PNG is what the page references.
#
# Data © OpenStreetMap contributors, ODbL. Attribution is printed on the figure
# and is required by the licence — do not remove it.
#
#   Rscript tools/office_map.R
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(osmdata); library(sf); library(ggplot2); library(cowplot); library(dplyr)
})

# --- Parameters you will want to edit --------------------------------------

# HAND-SET, and the whole point of the inset: OSM has no interior floor plans,
# so the office marker cannot come from data. Placed on the north-facing side
# of the building, toward its western end. For reference the Rockefeller
# footprint spans lon -72.29054..-72.28977 and lat 43.70569..43.70589, so a
# smaller lon moves the pin west and a larger lat moves it north. (318 is on
# the third floor; a 2D footprint cannot show that, so the floor is stated in
# the label instead.)
#
# No entrance is marked: there are several ways into the building and singling
# one out misleads more than it helps.
office <- c(lon = -72.29036, lat = 43.70583)

office_label <- "318 — 3rd floor"

campus_bbox <- c(-72.2940, 43.7028, -72.2858, 43.7082)  # outer panel extent

# Landmarks labelled on the campus panel. A map for orientation needs things a
# student already knows how to find; edit this list freely.
landmarks <- c("Baker Library", "Dartmouth Hall", "Collis Student Center")
green_label <- "Dartmouth Green"
inset_pad   <- 60      # metres of padding around the two buildings in the inset

dartmouth_green <- "#00693E"
out_png <- file.path("site-schmitt", "images", "office-map.png")
cache   <- file.path("tools", "osm-cache.rds")

# --- Fetch OSM (cached, so re-runs are fast and work offline) ---------------

fetch_osm <- function() {
  message("Querying Overpass… (cached after the first run)")
  bb <- campus_bbox
  grab <- function(key, value = NULL) {
    q <- opq(bbox = bb, timeout = 120)
    q <- if (is.null(value)) add_osm_feature(q, key = key)
         else add_osm_feature(q, key = key, value = value)
    osmdata_sf(q)
  }
  list(
    buildings = grab("building"),
    roads     = grab("highway", c("primary", "secondary", "tertiary",
                                  "residential", "service", "unclassified")),
    paths     = grab("highway", c("footway", "path", "pedestrian")),
    green     = grab("leisure", c("park", "common", "garden"))
  )
}

if (file.exists(cache)) {
  message("Using cached OSM data (delete ", cache, " to refetch).")
  osm <- readRDS(cache)
} else {
  osm <- fetch_osm()
  saveRDS(osm, cache)
}

# Project to UTM 18N so distances and the aspect ratio are correct. Plotting
# lon/lat directly would stretch the map noticeably at this latitude.
utm <- 32618
to_utm <- function(x) if (is.null(x) || !nrow(x)) NULL else st_transform(st_make_valid(x), utm)

polys <- function(o) {
  p <- o$osm_polygons
  m <- o$osm_multipolygons
  if (!is.null(m) && nrow(m)) {
    p <- bind_rows(
      p |> select(any_of(c("osm_id", "name"))),
      st_cast(m, "MULTIPOLYGON") |> select(any_of(c("osm_id", "name")))
    )
  }
  to_utm(p)
}

buildings <- polys(osm$buildings)
roads     <- to_utm(osm$roads$osm_lines)
paths     <- to_utm(osm$paths$osm_lines)
green     <- polys(osm$green)

stopifnot(!is.null(buildings), nrow(buildings) > 0)

# OSM names it "Rockefeller Center", not "Rockefeller Hall" — match loosely so
# a future rename upstream does not silently break the highlight.
rock   <- buildings |> filter(grepl("Rockefeller", name, ignore.case = TRUE))
silsby <- buildings |> filter(grepl("Silsby",      name, ignore.case = TRUE))
if (!nrow(rock))   stop("No Rockefeller footprint found in the OSM extract.")
if (!nrow(silsby)) warning("No Silsby footprint found — the inset will show only Rockefeller.")

pt <- function(v) st_transform(st_sfc(st_point(c(v[["lon"]], v[["lat"]])), crs = 4326), utm)
office_pt <- pt(office)

# --- Inset extent ----------------------------------------------------------

pair       <- if (nrow(silsby)) bind_rows(rock, silsby) else rock
inset_bb   <- st_bbox(st_buffer(st_union(pair), inset_pad))
inset_rect <- st_as_sfc(inset_bb)

campus_bb <- st_bbox(st_transform(
  st_as_sfc(st_bbox(c(xmin = campus_bbox[1], ymin = campus_bbox[2],
                      xmax = campus_bbox[3], ymax = campus_bbox[4]), crs = 4326)), utm))

lm_pts <- buildings |>
  filter(name %in% landmarks) |>
  group_by(name) |> summarise(.groups = "drop") |>
  st_centroid()

green_pt <- if (!is.null(green)) {
  green |> filter(name %in% green_label) |>
    group_by(name) |> summarise(.groups = "drop") |> st_centroid()
} else buildings[0, ]

# Sits above the highlighted footprint on the campus panel.
rock_lab <- st_coordinates(st_centroid(st_union(rock))); rock_lab[2] <- rock_lab[2] + 95

# --- Shared theme ----------------------------------------------------------

base_theme <- theme_void(base_size = 11) +
  theme(plot.background  = element_rect(fill = "white", colour = NA),
        panel.background = element_rect(fill = "#f7f7f5", colour = NA),
        plot.margin      = margin(2, 2, 2, 2))

# --- Outer panel: campus ---------------------------------------------------

main <- ggplot() +
  { if (!is.null(green)) geom_sf(data = green, fill = "#e4ece4", colour = NA) } +
  { if (!is.null(roads)) geom_sf(data = roads, colour = "#ffffff", linewidth = 0.9) } +
  { if (!is.null(paths)) geom_sf(data = paths, colour = "#e0ded8", linewidth = 0.3) } +
  geom_sf(data = buildings, fill = "#dcdad4", colour = "#cfccc5", linewidth = 0.15) +
  { if (nrow(silsby)) geom_sf(data = silsby, fill = "#9fc4b0", colour = "#7ba892", linewidth = 0.3) } +
  geom_sf(data = rock, fill = dartmouth_green, colour = dartmouth_green) +
  geom_sf(data = inset_rect, fill = NA, colour = "#333333", linewidth = 0.5) +
  { if (nrow(lm_pts)) geom_sf_text(data = lm_pts, aes(label = name), size = 2.7,
                                   colour = "#6b6b6b", fontface = "italic") } +
  { if (nrow(green_pt)) geom_sf_text(data = green_pt, aes(label = name), size = 2.9,
                                     colour = "#5d7d64", fontface = "italic") } +
  annotate("text", x = rock_lab[1], y = rock_lab[2], label = "Rockefeller",
           size = 3.2, fontface = "bold", colour = dartmouth_green, hjust = 0.5) +
  coord_sf(xlim = c(campus_bb["xmin"], campus_bb["xmax"]),
           ylim = c(campus_bb["ymin"], campus_bb["ymax"]), expand = FALSE) +
  base_theme

# --- Inset panel: the two halves -------------------------------------------

lab <- function(x, y, text, ...) annotate("label", x = x, y = y, label = text,
                                          size = 3.1, label.size = 0, fill = "white",
                                          alpha = 0.85, ...)

rock_c   <- st_coordinates(st_centroid(st_union(rock)))
silsby_c <- if (nrow(silsby)) st_coordinates(st_centroid(st_union(silsby))) else NULL
off_c    <- st_coordinates(office_pt)

inset <- ggplot() +
  { if (!is.null(paths)) geom_sf(data = paths, colour = "#d8d5cd", linewidth = 0.5) } +
  { if (!is.null(roads)) geom_sf(data = roads, colour = "#ffffff", linewidth = 2) } +
  geom_sf(data = buildings, fill = "#dcdad4", colour = "#cfccc5", linewidth = 0.2) +
  { if (nrow(silsby)) geom_sf(data = silsby, fill = "#9fc4b0", colour = "#7ba892", linewidth = 0.4) } +
  geom_sf(data = rock, fill = dartmouth_green, colour = dartmouth_green, alpha = 0.9) +
  geom_sf(data = office_pt, shape = 21, size = 4.5, stroke = 1.2,
          fill = "#d94801", colour = "white") +
  { if (!is.null(silsby_c)) lab(silsby_c[1], silsby_c[2], "Silsby Hall", colour = "#3d5c4c") } +
  lab(rock_c[1], rock_c[2] + 28, "Rockefeller", colour = dartmouth_green, fontface = "bold") +
  lab(off_c[1] + 42, off_c[2] + 8, office_label, colour = "#a03500") +
  coord_sf(xlim = c(inset_bb["xmin"], inset_bb["xmax"]),
           ylim = c(inset_bb["ymin"], inset_bb["ymax"]), expand = FALSE) +
  base_theme +
  theme(panel.border = element_rect(colour = "#333333", fill = NA, linewidth = 0.6))

# --- Compose ---------------------------------------------------------------

fig <- ggdraw() +
  draw_plot(main) +
  draw_plot(inset, x = 0.015, y = 0.015, width = 0.46, height = 0.46) +
  draw_label("Map data © OpenStreetMap contributors",
             x = 0.995, y = 0.012, hjust = 1, size = 6.5, colour = "#8a8a8a")

dir.create(dirname(out_png), showWarnings = FALSE, recursive = TRUE)
fig_w   <- 7.5
aspect  <- unname((campus_bb["xmax"] - campus_bb["xmin"]) /
                  (campus_bb["ymax"] - campus_bb["ymin"]))
fig_h   <- fig_w / aspect
ggsave(out_png, fig, width = fig_w, height = fig_h, dpi = 200, bg = "white")
message("Wrote ", out_png)
