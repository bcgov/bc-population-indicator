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
library(dygraphs) #for interactive chart plot
library(RColorBrewer) #for colour palette
library(leaflet) ## for interactive map


## simplifying the polygons in shapefile
cd <- ms_simplify(cd, keep = 0.01, keep_shapes = TRUE, explode = TRUE)

## aggregating small polygons
cd <- aggregate(cd, by = "CDUID")

## converting spatial file to dataframe
cd_plot <- fortify(cd, region = "CDUID")

## joining tabular and spatial data after c
cd_plot <- left_join(cd_plot, popn_pct, by = c("id" = "SGC"))

# ## assigning the columns for coordinates
# coordinates(popn_pt) <- ~coord.1 + coord.2
# 
# ## defining projection system
# proj4string(popn_pt) <- CRS("+init=epsg:4617")
# 
# ## joining with spatial polygons
# popn_pt <- spTransform(popn_pt, CRS(proj4string(cd)))
# popn_pt <- as.data.frame(popn_pt, stringsAsFactors=FALSE)


## ploting long-term BC population line graph
bc_plot <- ggplot(data = popn_bc, aes(x = Year, y = Population)) +
  geom_line() +
  theme_minimal() +
  theme(legend.title = element_text(size = 11, face = "bold"),
        text = element_text(family = "Verdana")) +
  theme_soe() 
plot(bc_plot)


## plotting regional district facet graph
rd_facet <- ggplot(data = popn_rd, aes(x = Year, y = Total)) +
  geom_line(show.legend = FALSE, size = 1) +
  scale_x_continuous(breaks = seq(1987, 2015, 4), expand=c(0,0)) +
  labs(ylab("Population")) +
  facet_wrap(~Regional.District, labeller = label_wrap_gen(width = 15, multi_line = TRUE)) +
  theme_soe_facet() +
  theme(legend.title = element_text(size = 11, face = "bold"),
        text = element_text(family = "Verdana"),
        legend.text = element_text(size = 10),
        axis.text.x = element_text(angle = 45, size = 6, vjust = 0.5),
        axis.text = element_text(size = 8)) 
plot(rd_facet)


## plotting chloropleth
## creating a Color Brewer (http://colorbrewer2.org/) palette for plotting
pal <- brewer.pal(9, "BrBG")[1:8]

rd_plot <- ggplot(data = cd_plot, aes(x = long, y = lat, group = group, fill = Total)) +
  geom_path() +
  geom_polygon() +
  # scale_fill_manual(values = pal, breaks = levels(cd_plot$Total)) +
  scale_fill_gradientn(colours = rev(pal),
                       guide = guide_colourbar(title = "Percent Change\nin BC Population")) +
  facet_wrap(~Year) +
  theme_minimal() +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        panel.grid = element_blank(),
        legend.title = element_text(size = 11, face = "bold"),
        text = element_text(family = "Verdana"))
plot(rd_plot)


## plotting points
pt_plot <- ggplot(data = cd_plot) +
  geom_polygon(aes(long, lat, group = group), fill = "grey20") +
  geom_path(aes(long, lat, group = group), colour = "grey45", size = 0.2) +
  geom_point(data = popn_pt, aes(coord.1, coord.2, size = Total), alpha = 0.6, 
             colour = "#ffd24d") +
  theme_minimal() +
    theme(axis.title = element_blank(),
          axis.text = element_blank(),
          panel.grid = element_blank(),
          legend.title = element_text(size = 11, face = "bold"),
          text = element_text(family = "Verdana"))
plot(pt_plot)


## plotting dygraph
dygraph(dy_plot_bc, main = "Population Change in British Columbia")
# dygraph(dy_plot_rd, main = "Population Change by Regional District")
