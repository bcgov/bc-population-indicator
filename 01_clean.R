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
library(tidyr) #for reformatting dataframes
library(reshape2) #format dataframe
library(rgdal) #for reading shapefile

## Tabular data files publically available from BC Stats on-line: 
## http://www.bcstats.gov.bc.ca/StatisticsBySubject/Demography/PopulationEstimates.aspx
## [license: BC Crown Copyright]
## Files located under Municipalities, Regional Districts & Development Regions section

## loading population data of 2001-05 and 2011-15
popn <- read.csv("Z:/sustainability/population/Population_Estimates.csv", stringsAsFactors = FALSE)
popn_bc <- read.csv("Z:/sustainability//population/BC_annual_population_estimates.csv", stringsAsFactors = FALSE)

## BC Census Division spatial data publically available from Statistics Canada on-line:
## 2011 Statistics Canada Census - Boundary files: http://www12.statcan.gc.ca/census-recensement/2011/geo/bound-limit/bound-limit-2011-eng.cfm
## (license: Statistics Canada Open License Agreement)
## Select -- Format: ArcGIS (.shp), Boundary: Census Divisions, Type: Cartographic Boundary File
## Unpackaged .zip file

## preparing census division shapefiles
cd <- readOGR(dsn = "Z:/sustainability/population/shapefile", layer = "gcd_000b11a_e", encoding = "ESRI Shapefile", stringsAsFactors = FALSE)

## extract shape for BC only
cd<- cd[cd$PRUID =="59", ] 

 
## clean dataframe 
popn_rd <- popn %>% 
  filter(Regional.District != "British Columbia") %>% 
  select(SGC, Regional.District, Year, Total)

# prepare dataframe for interactive dygraph
dy_plot_bc <- popn_bc
# dy_plot_rd <- select(popn_rd, -SGC)
# dy_plot_rd <- spread(dy_plot_rd, Regional.District, value = Total)

## format SGC code to match with CDUID code in shapefile for merging dataframes later
for (i in 1:length(popn_rd$SGC)) {
  if (nchar(popn_rd$SGC[i]) == 4) {
    popn_rd$SGC[i] <- sub("^", "590", popn_rd$SGC[i])
  }
  else {
    popn_rd$SGC[i] <- sub("^", "59", popn_rd$SGC[i])
  }
  popn_rd$SGC[i] <- substr(popn_rd$SGC[i], 0, 4)
}

## calculate annual change in population
## create a function to calculate percentage
pct <- function(x) {
  round((x-lag(x))/lag(x)*100, 0)
}

popn_pct <- popn_rd %>% 
  filter(Year == 1986 | Year == 1994 | Year == 2001 | Year == 2008 | Year == 2015) %>% 
  group_by(Regional.District) %>% 
  mutate_each(funs(pct), Total) %>%
  filter(Year != 1986)
  
## join coordinates to tabular data from shapefile for point plot
df <- data.frame(SGC = cd$CDUID, coord = coordinates(cd))
df$SGC <- as.character(df$SGC)
popn_pt <- left_join(popn_rd, df, by = c("SGC" = "SGC"))

## use only 2015 values
popn_pt <- filter(popn_pt, Year == 2015)
