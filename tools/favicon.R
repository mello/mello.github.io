# ---------------------------------------------------------------------------
# favicon.R — writes site-schmitt/images/favicon.png
#
# A Dartmouth-green rounded square with white initials. Deliberately NOT the
# College's shield, Lone Pine, or "D" logo: those are Dartmouth trademarks, and
# reproducing one on a personal site is a permissions question rather than a
# design one. The colour alone (Pantone 349, #00693E) reads as Dartmouth
# without borrowing a protected mark.
#
# 512px so it downsamples cleanly to the 16/32/180px sizes browsers ask for.
#
#   Rscript tools/favicon.R
# ---------------------------------------------------------------------------

library(grid)

out  <- file.path("site-schmitt", "images", "favicon.png")
size <- 512

png(out, width = size, height = size, bg = "transparent")
grid.newpage()
grid.roundrect(width = unit(1, "npc"), height = unit(1, "npc"),
               r = unit(0.18, "npc"), gp = gpar(fill = "#00693E", col = NA))
grid.text("SM", y = unit(0.47, "npc"),
          gp = gpar(col = "white", fontsize = size * 0.46, fontface = "bold"))
invisible(dev.off())
message("Wrote ", out)
