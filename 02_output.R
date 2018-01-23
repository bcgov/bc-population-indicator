# Copyright 2016 Province of British Columbia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

library(bcmaps) #for BC boundary
library(envreportutils) #soe theme
library(ggplot2) #for plotting
library(RColorBrewer) #for colour palette
library(png) #for inserting image to plot
library(grid) #for creating grid graphic
library(rprojroot) # for finding root of project
library(rmapshaper) # simplify map
library(sf) #sf ma
library(dplyr) #for joining dataframes
#library(patchwork) #combining 2 bar charts

## Find the root of the project so we can find the files in the directory tree.
root <- rprojroot::is_rstudio_project

## Load clean data if not already in local repository
if (!exists("popsummary")) load("tmp/sumdata.RData")

## @knitr pre

##font selection
chart_font_web <- "Verdana"

## @knitr line_plot

## simplifying rd sf map and aggregating small polygons for plotting
plotmapsf <- ms_simplify(rd, keep = .01)
# plot(st_geometry(plotmapsf))

## converting sf to sp and then to df
plotmap <- as(plotmapsf, "Spatial")
plotmapdf <- fortify(plotmap, region = "Regional_District")

## joining population summary tabular and spatial data
cd_plot <- left_join(plotmapdf, popsummary, by = c("id" = "Regional_District"))

## preparing image to insert to BC line graph
img_path <- root$find_file(file.path("source_image", "popn.png"))
img <- readPNG(img_path)
g <- rasterGrob(img, interpolate = TRUE)

## plotting long-term BC population line graph
bc_plot <- ggplot(data = popn_bc, aes(x = Year, y = popn_million)) +
  geom_line(colour = "#a63603", size = 1.5, alpha = 0.8) +
  xlab("") +
  ylab("B.C. Population (Million)") +
  annotate("text", x = 1925, y = 4.1, label = "When British Columbia joined Canada in 1871,\nthe population was estimated to be about 40,000 people.\nBritish Columbia's current population is\n 4.82 million people.",
           size = 5, family = "Verdana") +
  annotation_custom(g, xmin = 1975, xmax = 2000, ymin = 0.5, ymax = 2) +
  scale_x_continuous(limits = c(1867, 2016), breaks = seq(1881, 2016, 15), expand = c(0.02, 0)) +
  scale_y_continuous(limits = c(0, 5), expand = c(0.04, 0)) +
  theme_soe() +
  theme(axis.text = element_text(size = 14),
        panel.grid = element_blank(),
        axis.title.y = element_text(margin = margin(0, 10, 0, 0), size = 16),
        text = element_text(family = "Verdana"),
        plot.margin = unit(c(5, 5, 5, 5), "mm")) 
plot(bc_plot)

## @knitr barcharts

## plotting 2 barcharts for 2016 Greater Vancouver and other regional districts

gv_barchart <- ggplot(data = popn_gv, aes(x = Regional_District, y = popn_thousand)) +
  geom_bar(stat = "identity", position = "identity", fill = "#767676", 
           colour = "grey30", size = 0.2, alpha = 0.9) +
  labs(xlab("")) +
  labs(ylab("Population (*1000)")) +
  coord_flip() +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0), breaks = seq(0, 2500, 500), limits = c(0, 2600)) +
  theme_soe() +
  theme(axis.title.y = element_blank(),
        axis.title.x = element_text(margin = margin(10, 0, 0, 0), size = 14),
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12),
        legend.position = "none",
        panel.grid = element_blank(),
        plot.margin = unit(c(0, 5, 5, 15), "mm"),
        text = element_text(family = "Verdana"))

rest_barchart <- ggplot(data = popn_rest, aes(x = reorder(Regional_District, -popn_thousand), y = popn_thousand)) +
  geom_bar(stat = "identity", colour = "grey30", size = 0.3, alpha = 0.9, fill = "#ececec") +
  coord_flip() +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0), breaks = seq(0, 400, 80), limits = c(0, 400)) +
  theme_soe() +
  theme(axis.title = element_blank(),
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12),
        panel.grid = element_blank(),
        plot.margin = unit(c(15, 10, 5, 0), "mm"),
        legend.position = "none",
        text = element_text(family = "Verdana"))

multiplot(rest_barchart, gv_barchart, cols = 1, heights = c(1.1, 0.13))

## Using `patchwork`
# rest_barchart + gv_barchart + plot_layout(ncol = 1, heights = c(14, .5))
# rest_barchart / gv_barchart

## @knitr plot16

## plotting 2016 population density map
colrs <- c("#ffffe5", "#fee391", "#fe9929", "#662506")
names(colrs) <- catlab

popn_plot16 <- ggplot(data = cd_plot, aes(x = long, y = lat, group = group, fill = cat)) +
  geom_polygon(alpha = 0.9) +
  geom_path(colour = "grey50", size = 0.3) +
  coord_fixed() + 
  scale_fill_manual(values = colrs, drop = FALSE,
                    name = "2016\nPopulation Density\n(Population/km2)") +
  theme_minimal() +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        panel.grid = element_blank(),
        legend.title = element_text(size = 14, face = "bold"),
        legend.text = element_text(size = 13),
        legend.position = c(0.17, 0.15),
        plot.margin = unit(c(15, 5, 5, 5), "mm"),
        text = element_text(family = "Verdana"))
plot(popn_plot16)  

## @knitr change_map

## plotting chloropleth
## creating a colour brewer palette from http://colorbrewer2.org/
pal <- c(brewer.pal(5, "YlOrBr")[5:1], brewer.pal(3, "Greys"))

rd_plot <- ggplot(data = cd_plot, aes(x = long, y = lat, group = group, fill = percchange)) +
  geom_polygon(alpha = 0.9) +
  geom_path(colour = "grey50", size = 0.3) +
  coord_fixed() + 
  scale_fill_gradientn(limits = c(-50, 115), colours = rev(pal), 
                       guide = (guide_colourbar(title = "Percent Change\nin Population (1986-2016)",
                                                title.position = "bottom"))) +
  theme_minimal() +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        panel.grid = element_blank(),
        legend.title = element_text(size = 14, face = "bold"),
        legend.text = element_text(size = 13),
        legend.position = c(0.15, 0.2),
        text = element_text(family = "Verdana"),
        plot.margin = unit(c(5, 5, 5, 5), "mm"))
plot(rd_plot)

## @knitr stop

## saving plots as SVG

## create a folder to store the output plots
if (!exists("out")) dir.create('out', showWarnings = FALSE)

svg_px("./out/popn_line.svg", width = 650, height = 450)
plot(bc_plot)
dev.off()

svg_px("./out/barcharts.svg", width = 500, height = 500)
multiplot(rest_barchart, gv_barchart, cols = 1, heights = c(.9, 0.13))
dev.off()

svg_px("./out/popn_viz.svg", width = 500, height = 500)
plot(popn_plot16)
dev.off()

svg_px("./out/popn_pctplot.svg", width = 650, height = 550)
plot(rd_plot)
dev.off()

