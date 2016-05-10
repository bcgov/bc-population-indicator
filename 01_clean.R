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
library(envreportutils) #for order dataframe function
library(bcmaps) #for regional district map plot; package & details on GitHub -- https://github.com/bcgov/bcmaps

## Tabular data files publically available from BC Stats on-line: 
## http://www.bcstats.gov.bc.ca/StatisticsBySubject/Demography/PopulationEstimates.aspx
## [license: BC Crown Copyright]

## loading tabular annual population data for BC from 1867-2015
## downloaded directly from BC Stats and cleaned for machine-readable format
popn <- read.csv("Z:/sustainability/population/Population_Estimates.csv", stringsAsFactors = FALSE)

## loading tabular regional district population data from 1986-2015
## downloaded via search tool under Population by Age and Sex, first cell renamed to SGC for machine readable format
popn_bc <- read.csv("Z:/sustainability/population/BC_annual_population_estimates.csv", stringsAsFactors = FALSE)


## preparing regional district map for census division population display and area
cd <- regional_districts_disp
cd_area <- regional_districts_analysis
 
## extract regional district area values
area_vector <- sapply(slot(cd, "polygons"), slot, "area")
area_df <- data.frame(SGC = cd_area$CDUID, area = area_vector)

## format population values in BC dataframe
popn_bc <- popn_bc %>% 
  mutate(popn_million = round(Population/1000000, 2))

## calculate BC population change from 1986 - 2015
bc_change <- popn_bc$Population[popn_bc$Year == 2015] - popn_bc$Population[popn_bc$Year == 1986]
bc_pct <- bc_change/popn_bc$Population[popn_bc$Year == 1986]*100

## clean regional district dataframe 
popn_rd <- popn %>% 
  filter(Regional.District != "British Columbia") %>% 
  dplyr::select(SGC, Regional.District, Year, Total) %>% 
  mutate(popn_thousand = round(Total/1000, 0))
  
## format dash signs in regional district dataframe
popn_rd$Regional.District <- gsub("-", " - ", popn_rd$Regional.District)

## ordering regional districts based on average population size for facet plot
#popn_rd <- order_df(popn_rd, "Regional.District", "Total", mean, desc = TRUE)

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


## calculate total change in population from 1986 to 2015 in regional districts
## create a function to calculate percentage
pct <- function(x) {
  round((x-lag(x))/lag(x)*100, 0)
}

## for not overwriting the column to which the function is applied
vars <- names(popn_rd["Total"])
vars <- setNames(vars, paste0(vars, "_change"))

popn_sum <- popn_rd %>% 
  filter(Year == 1986 | Year == 2015) %>% 
  group_by(Regional.District) %>% 
  mutate_each_(funs(pct), vars) %>%
  filter(Year != 1986)

## ordering regional districts based on 2015 population
#popn_sum <- popn_sum[order(popn_sum$Total, decreasing = TRUE), ]

## creating new dataframe to separate Greater Vancouver from other rd with less population
popn_gv <- popn_sum %>% 
  filter(Regional.District == "Greater Vancouver")

popn_rest <- popn_sum %>% 
  filter(Regional.District != "Greater Vancouver")

## ordering other regionals districts dataframe based on 2015 population
#popn_rest <- popn_rest[order(popn_rest$popn_thousand, decreasing = TRUE), ]
popn_rest <- order_df(popn_rest, target_col = "Regional.District",
                      value_col = "popn_thousand", fun = sum, desc = TRUE)

## join popn_sum and regional district area dataframes to calculate population density
popn_sum <- left_join(popn_sum, area_df, by = c("SGC" = "SGC"))
popn_sum <- popn_sum %>%
  mutate(density = round(Total/(area/10^6), 0)) 

## create density labels and categories for plotting density map
catlab <- c("less than 10", "10 to 60", "61 to 200", "greater than 800")
popn_sum$cat <- cut(popn_sum$density, breaks = c(-1,10,60,200,900),
                    include.lowest=TRUE,
                    labels = catlab)


