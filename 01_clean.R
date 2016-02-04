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


## loading population data of 2001-05, and 2011-15 from BC Stats
popn01 <- read.csv("Z:/sustainability/population/BC_RD_popn2001-2011.csv", stringsAsFactors = FALSE)
popn11 <- read.csv("Z:/sustainability/population/BC_RD_popn2011-2015.csv", stringsAsFactors = FALSE)

## merge 01 and 11 dataframes
popn <- left_join(popn01, popn11, by = "SGC")
popn$Area.Type.x <- NULL
popn$Area.Type.y <- NULL
popn$Name.y <- NULL
popn$X2011.y <- NULL

## substitute "na" characters to NA
popn[popn == "na"] <- NA
popn$Name.x <- gsub("\\(See Notes)", "", popn$Name.x)

# ## delete regional district entries and use only subdivisions for plotting
# popn01 <- popn01 %>% 
#   filter(popn01$Area.Type != "RD" & popn01$Area.Type != "R")
# popn11 <- popn11 %>% 
#   filter(popn11$Area.Type != "RD" & popn11$Area.Type != "R")
# 
# ## take out indent in district names in both dataframes
# popn01$Name <- gsub("     ", "", popn01$Name)
# popn11$Name <- gsub("     ", "", popn11$Name)
# 
# ## compare district and municipality names of both files and set them to be the same for merging dataframe
# setdiff(popn01$Name, popn11$Name)
# setdiff(popn11$Name, popn01$Name)
# popn01$Name[popn01$Name == "100 Mile House"] <- "One Hundred Mile House"
# popn01$Name[popn01$Name == "Langley" & popn01$Area.Type == "C"] <- "Langley, City of"
# popn01$Name[popn01$Name == "Langley" & popn01$Area.Type == "DM"] <- "Langley, District Municipality"
# popn01$Name[popn01$Name == "North Vancouver" & popn01$Area.Type == "C"] <- "North Vancouver, City of"
# popn01$Name[popn01$Name == "North Vancouver" & popn01$Area.Type == "DM"] <- "North Vancouver, District Municipality"
# popn01$Name[popn01$Name == "Sechelt Ind Gov Dist  (Part)" ] <- "Sechelt Ind Gov Dist (Part-Powell River)"
# popn01$Name[popn01$Name == "Sechelt"] <- "Sechelt District Municipality"
# popn01$Name[popn01$Name == "Sechelt Ind Gov Dist (Part)"] <- "Sechelt Ind Gov Dist (Part-Sunshine Coast)"



