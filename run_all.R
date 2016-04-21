library(envreportbc) #for pdf font output

source("01_clean.R")
source("02_output.R")

## Make print version
mon_year <- format(Sys.Date(), "%B%Y")
outfile <- paste0("envreportbc_bc_population", mon_year, ".pdf")
rmarkdown::render("print_ver/popn.Rmd", output_file = outfile)
extrafont::embed_fonts(file.path("print_ver/", outfile))
