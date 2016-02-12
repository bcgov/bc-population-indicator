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

library(dplyr) #data munging
library(reshape2) #format dataframe
library(rgdal) # for reading shapefile

## Tabular data files publically available from BC Stats on-line: 
## http://www.bcstats.gov.bc.ca/StatisticsBySubject/Demography/PopulationEstimates.aspx
## [license: BC Crown Copyright]
## Files located under Municipalities, Regional Districts & Development Regions section,
## converted .xls files into machine-readable .csv files.

## loading population data of 2001-05 and 2011-15
popn01 <- read.csv("Z:/sustainability/population/BC_RD_popn2001-2011.csv", stringsAsFactors = FALSE)
popn11 <- read.csv("Z:/sustainability/population/BC_RD_popn2011-2015.csv", stringsAsFactors = FALSE)

## BC Census Division spatial data publically available from Statistics Canada on-line:
## 2011 Statistics Canada Census - Boundary files: http://www12.statcan.gc.ca/census-recensement/2011/geo/bound-limit/bound-limit-2011-eng.cfm
## (license: Statistics Canada Open License Agreement)
## Select -- Format: ArcGIS (.shp), Boundary: Census Divisions, Type: Cartographic Boundary File
## Unpackaged .zip file

## preparing census division shapefiles
cd <- readOGR(dsn = "data", layer = "gcd_000b11a_e", encoding = "ESRI Shapefile", stringsAsFactors = FALSE)

## extract shape for BC only
cd<- cd[cd$PRUID =="59", ] 

## merge 01 and 11 dataframes
popn <- left_join(popn01, popn11, by = "SGC")

## deselect unneeded columns
popn <- select(popn, -SGC, -Area.Type.x, -Area.Type.y, -Name.y, -X2011.y)

## substitute "na" characters to NA
popn[popn == "na"] <- NA

## format name
popn$Name.x <- gsub("\\(See Notes)", "", popn$Name.x)

## delete regional district entries and use only subdivisions for plotting
popn <- popn %>% 
  filter(popn$Area.Type.x == "RD" | popn$Area.Type.x == "R") 
# %>% 
#   filter(popn$Name.x != " Strathcona Regional Dist. ") # temporarily take out the rd that the 
#                                                       # shp file does not have


## take out indent in district names in the dataframe
popn$Name.x <- gsub("     ", "", popn$Name.x) 

## compare names of tabular and shp files and set them to be the same for merging dataframe
setdiff(cd$CDNAME, popn$Name.x)
setdiff(popn$Name.x, cd$CDNAME)
popn$Name.x[popn$Name.x == " Comox Regional District "] <- "Comox Valley"
popn$Name.x[popn$Name.x == " Comox-Strathcona "] <- "Strathcona"
popn$Name.x[popn$Name.x == "Northern Rockies "] <- "Northern Rockies"
popn$Name.x[popn$Name.x == "Kootenay-Boundary"] <- "Kootenay Boundary"

## create long data table for plotting
popn_long <- melt(popn, id.vars = "Name.x", variable.name = "year", value.name = "population")

## convert characters to numeric values
popn_long$population <- as.numeric(popn_long$population)

## format long table entries
popn_long$year <- gsub("X", "", popn_long$year)
popn_long$year <- gsub(".x", "", popn_long$year)
