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

library(sp) #for spatial files
library(maptools) #for fortify function
library(rgdal) # for spatial projection
library(bcmaps) #for BC boundary
library(raster) #for interesect and aggregate functions
library(rmapshaper) #simplifying the district boundaries; package & details on GitHub -- https://github.com/ateucher/rmapshaper
library(envreportutils) #soe theme
library(ggplot2) #for plotting
library(RColorBrewer) #for colour palette
library(png) #for inserting image to plot
library(grid) #for creating grid graphic
library(gridExtra)


## simplifying the polygons in shapefile
cd <- ms_simplify(cd, keep = 0.01, keep_shapes = TRUE, explode = TRUE)

## aggregating small polygons
cd <- aggregate(cd, by = "CDUID")

## converting spatial file to dataframe
cd_plot <- fortify(cd, region = "CDUID")

# ##categorise change and add Color Brewer (http://colorbrewer2.org/) palette:
# scale_colours <- c("#01665e", "#35978f", "#80cdc1", "#dfc27d", "#bf812d", "#8c510a")
# names(scale_colours) <- c("-41 to -28", "-27 to -14", "-13 to 0", "1 to 14", "15 - 28", "29 - 42")

# ## creating scale breaks for map plot
# popn_pct$category <- cut(popn_pct$Total_change,
#                          breaks = c(-Inf, -28, -14, 0, 14, 28, 42),
#                          labels = names(scale_colours),
#                          include.lowest = FALSE, right = TRUE, ordered_result = TRUE)
# popn_pct$colour_code <- scale_colours[popn_pct$category]

## joining tabular and spatial data
cd_plot <- left_join(cd_plot, popn_sum, by = c("id" = "SGC"))

## preparing image to insert to BC line graph
img <- readPNG("img/popn.png")
g <- rasterGrob(img, interpolate = TRUE)


## ploting long-term BC population line graph
bc_plot <- ggplot(data = popn_bc, aes(x = Year, y = popn_million)) +
  geom_line(colour = "#a63603", size = 1.5, alpha = 0.85) +
  xlab("") +
  ylab("B.C. Population(Million)") +
  annotation_custom(g, xmin = 1888, xmax = 1925, ymin = 2.3, ymax = 4.8) +
  scale_x_continuous(limits = c(1867, 2015), breaks = seq(1880, 2015, 15), expand = c(0.02, 0)) +
  scale_y_continuous(limits = c(0, 5), expand = c(0.04, 0)) +
  theme_soe() +
  theme(panel.grid = element_blank(),
        axis.text.x = element_text(size = 8),
        axis.text.y = element_text(size = 8),
        axis.title = element_text(size = 12),
        text = element_text(family = "Verdana")) 
plot(bc_plot)

ggsave("./out/popn_line.png", plot = bc_plot, type = "cairo-png", 
       width = 7.4, height = 5.3, units = "in", dpi = 100)


## plotting regional district facet graph
rd_facet <- ggplot(data = popn_rd, aes(x = Year, y = popn_thousand)) +
  geom_line(show.legend = FALSE, colour = "#a63603", size = 0.8, alpha = 0.85) +
  scale_x_continuous(breaks = seq(1991, 2015, 8), expand=c(0,0)) +
  labs(xlab("")) +
  labs(ylab("Population (*1000)")) +
  facet_wrap(~Regional.District, labeller = label_wrap_gen(width = 15, multi_line = TRUE)) +
  theme_soe_facet() +
  theme(panel.grid = element_blank(),
        axis.text.x = element_text(size = 8, hjust = 0.7),
        axis.text.y = element_text(size = 8),
        axis.title = element_text(size = 12),
        plot.margin = unit(c(10, 0, 0, 0), "mm"), 
        text = element_text(family = "Verdana"))
plot(rd_facet)

ggsave("./out/popn_facet.png", plot = rd_facet, type = "cairo-png",
       width = 8.6, height = 6.5, units = "in", dpi = 100)


## plotting 2 barcharts for 2015 Greater Vancouver and other regional districts
pal15 <- brewer.pal(5, "YlOrBr")

gv_barchart <- ggplot(data = popn_gv, aes(x = Regional.District, y = popn_thousand)) +
  geom_bar(stat = "identity", position = "identity", fill = brewer.pal(5, "YlOrBr")[5], 
           colour = "grey30", size = 0.2, alpha = 0.9) +
  coord_flip() +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_fill_gradientn(colours = pal15) +
  theme_soe() +
  theme(axis.title = element_blank(),
        axis.text = element_text(size = 11),
        legend.position = "none",
        panel.grid = element_blank(),
        plot.margin = unit(c(0, 15, 15, 21), "mm"),
        text = element_text(family = "Verdana")) 
plot(gv_barchart)

rest_barchart <- ggplot(data = popn_rest, aes(x = Regional.District, y = popn_thousand, fill = popn_thousand)) +
  geom_bar(stat = "identity", position = "identity", colour = "grey30", size = 0.3, alpha = 0.9) +
  coord_flip() +
  scale_x_discrete(expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0), breaks = seq(0, 400, 80), limits = c(0, 400)) +
  scale_fill_gradientn(colours = brewer.pal(6, "YlOrBr")[1:2]) +
  theme_soe() +
  theme(axis.title = element_blank(),
        axis.text = element_text(size = 11),
        panel.grid = element_blank(),
        plot.margin = unit(c(10, 15, 5, 5), "mm"),
        legend.position = "none",
        text = element_text(family = "Verdana")) 
plot(rest_barchart)

png(filename = "./out/barcharts.png", width = 470, height = 520, units = "px", type = "cairo-png")
multiplot(rest_barchart, gv_barchart, cols = 1, heights = c(0.9, 0.14))
dev.off()


## plotting 2015 population map
popn_plot15 <- ggplot(data = cd_plot, aes(x = long, y = lat, group = group, fill = popn_thousand)) +
  geom_polygon(alpha = 0.9) +
  geom_path(colour = "grey30", size = 0.4) +
  scale_fill_gradientn(colours = pal15, guide = guide_colorbar(title = "Population\nin 2015", 
                                                               title.position = "bottom")) +
  theme_minimal() +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        panel.grid = element_blank(),
        legend.title = element_text(size = 14, face = "bold"),
        legend.text = element_text(size = 11),
        legend.position = c(0.15, 0.2),
        plot.margin = unit(c(30, 0, 0, 10), "mm"),
        text = element_text(family = "Verdana"))
plot(popn_plot15)  

png(filename = "./out/popn_viz.png", width = 460, height = 425, units = "px", type = "cairo-png")
multiplot(popn_plot15)
dev.off()

# grid.arrange(popn_gv, popn_rest, ncol = 2)

# png(filename = "./out/popn_viz.png", width = 930, height = 465, units = "px", type = "cairo-png")
# multiplot(popn_plot15, barchart, cols = 2, widths = c(1.3, 1))
# dev.off()

## plotting chloropleth
## creating a colour brewer palette from http://colorbrewer2.org/
pal <- c(brewer.pal(5, "YlOrBr")[5:1], brewer.pal(3, "Greys"))
# pal <- c("#a63603", "#B25328", "#BE704C", "#CA8D71", "#D7AA95", "#f0f0f0", "#bdbdbd", "#636363")

rd_plot <- ggplot(data = cd_plot, aes(x = long, y = lat, group = group, fill = Total_change)) +
  geom_polygon(alpha = 0.9) +
  geom_path(colour = "grey30", size = 0.3) +
  # scale_fill_manual(values = scale_colours, drop = FALSE,
  #                   guide = guide_legend(title = "Change Of B.C.\nPopulation\nin the Last\n30 Years (%)")) +
  scale_fill_gradientn(limits = c(-50, 110), colours = rev(pal), 
                       guide = (guide_colourbar(title = "Percent Change\nin Population\n(1986-2015)"))) +
  theme_minimal() +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        panel.grid = element_blank(),
        legend.text = element_text(size = 8),
        legend.title = element_text(size = 10, face = "bold"),
        text = element_text(family = "Verdana"))
plot(rd_plot)

ggsave("./out/popn_pctplot.png", plot = rd_plot, type = "cairo-png",
       width = 8.4, height = 5.5, units = "in", dpi = 100)
