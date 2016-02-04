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


## loading population data of 2001-05, and 2011-15 from BC Stats
popn01 <- read.csv("Z:/sustainability/population/BC_RD_popn2001-2011.csv", stringsAsFactors = FALSE)
popn11 <- read.csv("Z:/sustainability/population/BC_RD_popn2011-2015.csv", stringsAsFactors = FALSE)

## preparing census district shapefiles from Statistics Canada
cd <- readOGR(dsn = "data", layer = "gcd_000b11a_e", encoding = "ESRI Shapefile", stringsAsFactors = FALSE)

## extract shape for BC only
cd<- cd[cd$PRUID =="59", ] 

## merge 01 and 11 dataframes
popn <- left_join(popn01, popn11, by = "SGC")
popn$SGC <- NULL
popn$Area.Type.x <- NULL
popn$Area.Type.y <- NULL
popn$Name.y <- NULL
popn$X2011.y <- NULL

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

