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


library(envreportbc) #for pdf font output

source("01_clean.R")
source("02_output.R")

## Make print version
mon_year <- format(Sys.Date(), "%B%Y")
outfile <- paste0("EnvReportBC_BC_population_", mon_year, ".pdf")
rmarkdown::render("print_ver/popn.Rmd", output_file = outfile)
extrafont::embed_fonts(file.path("print_ver/", outfile))
