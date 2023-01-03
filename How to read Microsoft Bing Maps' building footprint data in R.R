# How to read Microsoft Bing Maps' building footprint data in R
# Note in Japanese: https://qiita.com/3tky/items/8eb2aaa81d283edbacfd
###################

#---------------------------
library(mapview)
library(sf)
library(data.table)
library(dplyr)
library(mapedit)

#---------------------------
# check the current working directory (wd)
getwd()
# make a directory for managing data
dir.create("MSBuildingFootprint")
# change wd to the directory
setwd("./MSBuildingFootprint/")
getwd()
# make directories for saving data
dir.create("Input")
dir.create("Output")

#---------------------------
# read building coverage data
building_coverage <- "https://minedbuildings.blob.core.windows.net/global-buildings/buildings-coverage.geojson" %>%
  sf::st_read()
# check the map of the building coverage 
mapview::mapview(building_coverage)
# select target grids from map viewer (in this example, we select grids covering Bangkok city, Thailand)

bc_Bangkok <- mapedit::selectFeatures(building_coverage)
## Check the selected data
## > bc_Bangkok$QuadKey
## [1] "132203132" "132203133" "132203310" "132203311"

#---------------------------
# read url-links data to building footprint
links <- "https://minedbuildings.blob.core.windows.net/global-buildings/dataset-links.csv" %>%
  data.table::fread()
# select url-links of Bangkok
links_Bangkok <- links %>%
  dplyr::filter(Location=="Thailand") %>%
  dplyr::filter(QuadKey %in% bc_Bangkok$QuadKey)

#---------------------------
# loop for downloading, decompressing, and reading data
building_footprint <- NULL
for(i in 1:nrow(links_Bangkok)){
  # download csv.gz file
  download.file(links_Bangkok$Url[i], paste0("Input/d",i,".csv.gz"))
  # unzip csv.gz file
  R.utils::gunzip(paste0("Input/",list.files("./Input")[i]))
  # change file-extension from csv to geojson <see the Note below>
  file.rename(paste0("Input/d",i,".csv"), paste0("Input/d",i,".geojson"))
  # read geojson file
  temp <- sf::st_read(paste0("Input/d",i,".geojson"))
  # bind geojson files
  building_footprint <- dplyr::bind_rows(building_footprint, temp)
  rm(temp)
}

#---------------------------
# write binded building footprint data as geojson 
sf::st_write(building_footprint,"Output/BF_Bangkok.geojson")
# write binded building footprint data as shapfile
sf::st_write(building_footprint,"Output/BF_Bangkok.shp")