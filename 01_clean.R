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

library(curl) #pull data from web
library(readr) #data import
library(dplyr) #data munging
library(bcmaps) #for BC regional district map
library(sf) #sf map object
library(stringr) #modifying character strings
library(units) #unit conversion

## Tabular data files publically available from BC Stats on-line:
## https://www2.gov.bc.ca/gov/content?id=36D1A7A4BEE248598281824C13CB65B6
## [licence: B.C. Crown Copyright]

## Download the British Columbia Total Population Estimates Data 1867-2017 (July 1st, 2017)
tmp <- dir.create("tmp", showWarnings = FALSE)
annual_file <- "https://www2.gov.bc.ca/assets/gov/data/statistics/people-population-community/population/pop_bc_annual_estimates.csv"
bcpopdata <- curl_download(annual_file, destfile = "tmp/annual_file.csv")

## Manually download and access the regional district population data from 1986-2016 
## via online applicationtool here: https://www.bcstats.gov.bc.ca/apps/PopulationEstimates.aspx
# path <- "~/soe_pickaxe/Operations ORCS/Data - Working/sustainability/population/2018/"
bcregpopdata <- "data/Population_Projections.csv"


## Read in and clean BC population CSV file
popn_bc_1 = read_csv(bcpopdata,
                    skip = 2,
                    n_max = 104,
                    col_types = "cn") %>%
  rename(Population = `Population: June 1`) %>%
  select(Year, Population) %>%
  na.omit() %>%
  filter(Year != "Year") %>%
  mutate(popn_million = round(Population / 1000000, 2), 
         Year = as.integer(Year))

popn_bc_2 = read_csv(bcpopdata,
                     skip = 109,
                     n_max = 52,
                     col_types = "cn") %>%
  rename(Population = `Population: July 1`) %>%
  select(Year, Population) %>%
  na.omit() %>%
  filter(Year != "Year") %>%
  mutate(popn_million = round(Population / 1000000, 2), 
         Year = as.integer(Year))

popn_bc = bind_rows(popn_bc_1,
                    popn_bc_2)

## Read in and clean BC population by Regional District CSV file - adjust names to official names
popn <- read_csv(bcregpopdata) %>%
  select(Regional_District = `Regional District`, Year, Population = `Pop`) %>%
  filter(Regional_District != "British Columbia") %>%
  mutate(
         Regional_District = str_replace(Regional_District, "-", " - "), 
         Regional_District = recode(Regional_District,
                                    `Powell River` = "qathet",
                                    `Columbia - Shuswap` = "Columbia Shuswap"),
         popn_thousand = round(Population / 1000, 0))

## Calculate BC population change for 1986 to 2017
bc_pop_change <- popn_bc %>% 
  filter(Year %in% c(1986, max(Year))) %>%
  mutate(popchange = Population-lag(Population)) %>% 
  mutate(percchange = round((popchange/lag(Population) * 100), digits = 0)) %>% 
  filter(Year == max(Year)) %>% 
  select(-Year) 
  

## Current Population by RD
popn_sum_by_RD_current <- popn %>% filter(Year == max(Year)) 

## Total BC Population from both data files - check if match
popn_tot_from_RD_current <- popn_sum_by_RD_current %>% pull(Population) %>% sum()
popn_bc %>% filter(Year == max(Year)) %>% pull(Population)

## df to separate Metro Vancouver from other RD with smaller population sizes and
## order other rd df based on current population size
popn_mv <- popn_sum_by_RD_current %>%
  filter(Regional_District == "Metro Vancouver")

popn_rest <- popn_sum_by_RD_current %>%
  filter(Regional_District != "Metro Vancouver")
  
## Combine RDs with Northern Rockies Regional Municipality, fix names to match those in the bcstats data
rd <- combine_nr_rd() %>%
  select(ADMIN_AREA_BOUNDARY_TYPE, Regional_District = ADMIN_AREA_NAME) %>%
  mutate(Regional_District = str_replace(Regional_District, "-", " - "), 
         Regional_District = str_replace(
           Regional_District, 
           c("Regional District of |Regional District| Regional Municipality"), ""
         ), 
         Regional_District = str_replace(Regional_District, 
                                         "Stikine Region \\(Unincorporated\\)", "Stikine"), 
         Regional_District = str_trim(Regional_District, side = "both"), 
         Regional_District = ifelse(Regional_District %in% c("Kootenay Boundary",
                                                             "Okanagan Similkameen",
                                                             "Thompson Nicola",
                                                             "Bulkley Nechako"), 
                                    str_replace(Regional_District, "\\s+", " - "), 
                                    Regional_District))

## Check that RD names are matching and fix above with str_replace() before joining popn_sum & area_df
# (diff1 <- setdiff(popn_sum_by_RD_current$Regional_District, rd$Regional_District))
# (diff2 <- setdiff(area_df$Regional_District, popn_sum$Regional_District))

## Clip out water, recalculate areas in km2
rd <- st_intersection(rd, bc_bound()) %>% 
  group_by(Regional_District) %>% 
  summarise() %>% 
  mutate(area = as.numeric(set_units(st_area(.), km^2)))

popn_den <- popn_sum_by_RD_current %>% 
  left_join(st_set_geometry(rd, NULL), by = "Regional_District") %>% 
  mutate(density = round(Population/as.numeric(area), 0))

## create density labels and categories for plotting density map
# catlab <- c("less than 10", "10 to 60", "61 to 200", "greater than 900")
catlab = c("0 - 2","2 - 5", "5 - 10", " 10 - 50", "50 - 100", "100 - 1000", "> 1000")
popn_den$cat <- cut(
  # popn_den$density, breaks = c(-1,10,60,200,1000),
  popn_den$density, breaks = c(-1, 2, 5,10, 50, 100, 1000, 1100),
                    include.lowest=TRUE,
                    labels = catlab)

## Calculate total change in population from 1986 to 2017 in regional districts
popn_change <- popn %>% 
  filter(Year %in% c(min(Year), max(Year))) %>% 
  group_by(Regional_District) %>% 
  mutate(popchange = Population-lag(Population)) %>% 
  mutate(percchange = round((popchange/lag(Total) * 100), digits = 0)) %>% 
  filter(Year == max(Year)) %>% 
  select(-Year) 
 
## Combine density and change metrics into one df  
popsummary <- popn_change %>% 
  select(Regional_District, popchange, percchange) %>% 
  left_join(popn_den, by = "Regional_District")

# Create tmp folder if not already there and store objects in local repository
if (!exists("tmp")) dir.create("tmp", showWarnings = FALSE)
save(popn_bc, catlab, popn_gv, popn_rest, rd, popsummary, file = "tmp/sumdata.RData")

