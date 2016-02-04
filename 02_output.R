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
library(ggplot2)

## preparing census subdivision shapefiles from Statistics Canada
# cd <- readOGR(dsn = "data", layer = "gcd_000b11a_e", encoding = "ESRI Shapefile", stringsAsFactors = FALSE)
csd <- readOGR(dsn = "data", layer = "gcsd000b11a_e", encoding = "ESRI Shapefile", stringsAsFactors = FALSE)

## extract shape for BC only
csd <- csd[csd$PRUID == "59", ] 
