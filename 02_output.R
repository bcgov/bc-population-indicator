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

# ## preparing census subdivision shapefiles from Statistics Canada
# csd <- readOGR(dsn = "data", layer = "gcsd000b11a_e", encoding = "ESRI Shapefile", stringsAsFactors = FALSE)
# 
# # ## extract shape for BC only
# csd <- csd[csd$PRUID == "59", ]

## Simplify the polygons in shapefile
cd <- ms_simplify(cd, keep = 0.01, keep_shapes = TRUE, explode = TRUE)

## aggregating small polygons
cd <- aggregate(cd, by = "CDUID")

## converting spatial file to dataframe
cd_plot <- fortify(cd, region = "CDUID")

## joining tabular and spatial data after c
cd_plot <- left_join(cd_plot, popn_long, by = c("id" = "SGC"))


## creating a Color Brewer (http://colorbrewer2.org/) palette for plotting
pal <- brewer.pal(7, "BrBG")[1:6]

## plotting
popn_plot <- ggplot(data = cd_plot, aes(x = long, y = lat, group = group, fill = population)) +
  geom_path() +
  geom_polygon() +
  scale_fill_manual(colours = rev(pal), 
                       guide = guide_colourbar(title = "Percent Change\nin BC Population")) +
  facet_wrap(~year, ncol = 5) +
  theme_minimal() +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        panel.grid = element_blank(),
        legend.title = element_text(size = 11, face = "bold"),
        text = element_text(family = "Verdana"))
plot(popn_plot)
