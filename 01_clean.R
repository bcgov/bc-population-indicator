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

library(readr) #data import
library(dplyr) #data munging
library(bcmaps) #for BC regional district map
library(sf) #sf map object
library(stringr) #modifying character strings

## Tabular data files publically available from BC Stats on-line:
## https://www2.gov.bc.ca/gov/content?id=36D1A7A4BEE248598281824C13CB65B6
## [licence: B.C. Crown Copyright]

## annual population data for BC from 1867-2017 downloaded directly from BC Stats
bcregpopdata <- "~/soe_pickaxe/Operations ORCS/Data - Working/sustainability/population/2018/Population_Estimates.csv"

## regional district population data from 1986-2016 downloaded via search tool here: https://www.bcstats.gov.bc.ca/apps/PopulationEstimates.aspx
bcpopdata <- "~/soe_pickaxe/Operations ORCS/Data - Working/sustainability/population/2018/BC annual population estimates.csv"

## read in and clean BC population CSV file
popn_bc <-
  read_csv(bcpopdata,
           skip = 2,
           n_max = 155,
           col_types = "cn") %>%
  rename(Population = `Population: June 1`) %>%
  na.omit() %>%
  filter("Year" != Year) %>%
  mutate(popn_million = round(Population / 1000000, 2))



## read in and clean BC population by Regional District CSV file
popn <- read_csv(bcregpopdata) %>%
  select(-Gender) %>%
  rename(SGC = X1) %>%
  filter(`Regional District` != "British Columbia") %>%
  mutate(popn_thousand = round(Total / 1000, 0)) %>%
  rename(Regional_District = `Regional District`) %>%
  mutate(Regional_District = str_replace(Regional_District, "-", " - "))

## 2016 Population by RD
popn_sum <- popn %>%
  group_by(Regional_District) %>%
  filter(Year == 2016)

## df to separate Greater Vancouver from other RD with smaller population sizes and
## order other rd df based on 2016 population size
popn_gv <- popn_sum %>%
  filter(Regional_District == "Greater Vancouver")

popn_rest <- popn_sum %>%
  filter(Regional_District != "Greater Vancouver") %>% 
  arrange(desc(popn_thousand))
  


## Combine RDs with Northern Rockies Regional Municipality
mun <- get_layer("municipalities") %>%
  filter(ADMIN_AREA_ABBREVIATION == "NRRM") %>%
  select(ADMIN_AREA_TYPE, ADMIN_AREA_NAME, SHAPE_Area, SHAPE)

rdplusmun <- get_layer("regional_districts") %>%
  select(ADMIN_AREA_TYPE, ADMIN_AREA_NAME, SHAPE_Area, SHAPE) %>%
  rbind(mun) 

rd <- rdplusmun %>%
  mutate(ADMIN_AREA_NAME = str_replace(ADMIN_AREA_NAME, "-", " - ")) %>%
  mutate(ADMIN_AREA_NAME = str_replace(
    ADMIN_AREA_NAME, c("Regional District of |Regional District| Regional Municipality"), "")) %>%
  mutate(ADMIN_AREA_NAME = str_replace(ADMIN_AREA_NAME, "Stikine  \\(Unincorporated\\)", "Stikine")) %>%
  mutate(ADMIN_AREA_NAME = str_trim(ADMIN_AREA_NAME, side = "right")) %>%
  mutate(ADMIN_AREA_NAME = str_replace(ADMIN_AREA_NAME, "Kootenay Boundary", "Kootenay - Boundary")) %>%
  mutate(ADMIN_AREA_NAME = str_replace(ADMIN_AREA_NAME, "Okanagan Similkameen", "Okanagan - Similkameen")) %>%
  mutate(ADMIN_AREA_NAME = str_replace(ADMIN_AREA_NAME, "Thompson Nicola", "Thompson - Nicola")) %>%
  mutate(ADMIN_AREA_NAME = str_replace(ADMIN_AREA_NAME, "Bulkley Nechako", "Bulkley - Nechako")) %>%
  mutate(ADMIN_AREA_NAME = str_replace(ADMIN_AREA_NAME, "Metro Vancouver", "Greater Vancouver")) %>%
  mutate(ADMIN_AREA_NAME = str_replace(ADMIN_AREA_NAME, "North Coast", "Skeena - Queen Charlotte"))



## 2016 Population Density population/km2
## extract regional district area values
area_vector <-  rd$SHAPE_Area
area_df <- data.frame(Regional_District = rd$ADMIN_AREA_NAME,
             area = area_vector)

## Check that RD names are matching and fix above wuth str_replace() before joining popn_sum & area_df
# (diff1 <- setdiff(popn_sum$Regional_District, area_df$Regional_District))
# (diff2 <- setdiff(area_df$Regional_District, popn_sum$Regional_District))

popn_den <- popn_sum %>% 
  left_join(area_df, by = c("Regional_District" = "Regional_District")) %>% 
  mutate(density = round(Total/(area/10^6), 0))

## create density labels and categories for plotting density map
catlab <- c("less than 10", "10 to 60", "61 to 100", "greater than 600")
popn_den$cat <- cut(popn_den$density, breaks = c(-1,10,60,100,700),
                    include.lowest=TRUE,
                    labels = catlab)



## calculate total change in population from 1986 to 2015 in regional districts
popn_change <- popn %>% 
  filter(Year == 1986 | Year == 2016) %>% 
  group_by(Regional_District) %>% 
  mutate(popchange = Total[Year==2016] - Total[Year==1986]) %>% 
  mutate(percchange = round(((Total-lag(Total))/lag(Total) * 100), digits = 0)) %>% 
  filter(Year == 2016) %>% 
  select(-Year)



# Create tmp folder if not already there and store objects in local repository
if (!exists("tmp")) dir.create("tmp", showWarnings = FALSE)
save(pop_bc, popn_gv, popn_rest, rdplusmun, popn_den, popn_change, file = "tmp/sumdata.RData")

