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
cd <- readOGR(dsn = "Z:/sustainability/population/shapefile", layer = "gcd_000b11a_e", encoding = "ESRI Shapefile", stringsAsFactors = FALSE)

## extract shape for BC only
cd<- cd[cd$PRUID =="59", ] 

## merge 01 and 11 dataframes
popn <- left_join(popn01, popn11, by = "SGC") 
 
## clean dataframe 
popn <-  popn %>% 
  filter(popn$Area.Type.x == "RD" | popn$Area.Type.x == "R") %>% 
  select(-Area.Type.x, -Area.Type.y, -Name.y, -X2011.y)

## substitute "na" characters to NA
popn[popn == "na"] <- NA

## format name
popn$Name.x <- gsub("\\(See Notes)", "", popn$Name.x)
popn$Name.x <- gsub("     ", "", popn$Name.x) 


## create long data table for plotting
popn_long <- melt(popn, id.vars = c("Name.x", "SGC"), variable.name = "year", value.name = "population")

## convert characters to numeric values
popn_long$population <- as.numeric(popn_long$population)

## format long table entries
popn_long$year <- gsub("X", "", popn_long$year)
popn_long$year <- gsub(".x", "", popn_long$year)

## format SGC code to match with CDUID code in shapefile for merging dataframes later
for (i in 1:length(popn_long$SGC)) {
  if (nchar(popn_long$SGC[i]) == 4) {
    popn_long$SGC[i] <- sub("^", "590", popn_long$SGC[i])
  }
  else {
    popn_long$SGC[i] <- sub("^", "59", popn_long$SGC[i])
  }
  popn_long$SGC[i] <- substr(popn_long$SGC[i], 0, 4)
}


## calculate annual change in population
## create a function to calculate percentage
pct <- function(x) {
  (lag(x)-x)/x*100
}

popn_long <- popn_long %>% 
  group_by(Name.x) %>% 
  mutate_each(funs(pct), population) %>% 
  filter(year != 2001)
