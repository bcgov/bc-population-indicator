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


## simplifying the polygons in shapefile
cd <- ms_simplify(cd, keep = 0.01, keep_shapes = TRUE, explode = TRUE)

## aggregating small polygons
cd <- aggregate(cd, by = "CDUID")

## converting spatial file to dataframe
cd_plot <- fortify(cd, region = "CDUID")

## joining tabular and spatial data after c
cd_plot <- left_join(cd_plot, popn_rd, by = c("id" = "SGC"))

## assigning the columns for coordinates
coordinates(popn_rd) <- ~coord.1 + coord.2

## defining projection system
proj4string(popn_rd) <- CRS("+init=epsg:4617")

## joining with spatial polygons
popn_pt <- spTransform(popn_rd, CRS(proj4string(cd)))
popn_pt <- as.data.frame(popn_pt, stringsAsFactors=FALSE)


## plotting points
pt_plot <- ggplot(data = cd_plot) +
  geom_polygon(aes(long, lat, group = group), fill = "grey20") +
  geom_path(aes(long, lat, group = group), colour = "grey45", size = 0.2) +
  geom_point(data = popn_pt, aes(coord.1, coord.2, size = Total), alpha = 0.6, 
             colour = "#ffd24d") +
  facet_wrap(~Year, ncol = 5) +
  theme_minimal() +
    theme(axis.title = element_blank(),
          axis.text = element_blank(),
          panel.grid = element_blank(),
          legend.title = element_text(size = 11, face = "bold"),
          text = element_text(family = "Verdana"))
plot(pt_plot)

## creating a Color Brewer (http://colorbrewer2.org/) palette for plotting
# pal <- brewer.pal(9, "BrBG")[1:6]

## plotting chloropleth
# popn_plot <- ggplot(data = cd_plot, aes(x = long, y = lat, group = group, fill = Total)) +
#   geom_path() +
#   geom_polygon() +
#   scale_fill_gradientn(colours = rev(pal),
#                        guide = guide_colourbar(title = "Percent Change\nin BC Population")) +
#   facet_wrap(~Year, ncol = 5) +
#   theme_minimal() +
#   theme(axis.title = element_blank(),
#         axis.text = element_blank(),
#         panel.grid = element_blank(),
#         legend.title = element_text(size = 11, face = "bold"),
#         text = element_text(family = "Verdana"))
# plot(popn_plot)


## plotting dygraph
dygraph(dy_plot_bc, main = "Population Change in British Columbia")
dygraph(dy_plot_rd, main = "Population Change by Regional District")
