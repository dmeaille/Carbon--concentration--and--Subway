# @author : Davi Méaille
# Created : 15/07/2022
# Last modification : 01/10/2022
# Description : 
# 
# This file extract the geographical data for pollution 
# for the cities that have opened a subway in the 
# period 1998-2018, based on spatial polygons designating 
# the cities. Relevant information are to be found in 
# the file boundingboxWORLD.csv. 

# set dir to the location of the file boundingboxWORLD.csv
dir = "C:\\Users\\davim\\OneDrive\\Desktop\\Informatique\\R\\Archive\\MIR Florian"

setwd(dir)

library(sf)
library(raster)
library(sp)
library(tidyverse)


city <- read.csv2("boundingboxWORLD.csv")

colnames(city)[1] <- "name" 

city <- city %>% select(name, longmin, latmin, longmax, latmax, X)
city$longmax <- as.numeric(city$longmax)
city$longmin <- as.numeric(city$longmin)
city$latmax <- as.numeric(city$latmax)
city$latmin <- as.numeric(city$latmin)

ls = list()


# to work with raster, we need a list of SpatialPolygon, one for 
# each city that we want to match 
for (i in 1:nrow(city)){
  data <- matrix(vector(), 5, 2, dimnames=list(c()))
  data[1,] <- c(city$longmax[i], city$latmax[i])
  data[2,] <- c(city$longmax[i], city$latmin[i])
  data[3,] <- c(city$longmin[i], city$latmin[i])
  data[4,] <- c(city$longmin[i], city$latmax[i])
  data[5,] <- c(city$longmax[i], city$latmax[i])
  p = Polygon(data)
  ps = Polygons(list(p),1)
  poly = SpatialPolygons(list(ps))
  proj4string(poly) <- CRS("+proj=longlat +datum=WGS84 +no_defs ") # we retrieved it from the crs of the raster files
  
  
  ls[[i]] <- poly

}


# a nice way to get a date format that will be useful to select each time the cities that we want to match 
for (i in 1:length(city[[1]])) {
  if (nchar(city[[6]][[i]])==6) {
    city[[6]][[i]] <- paste0(substr(city[[6]][[i]], 1, 4), "-0", substr(city[[6]][[i]], 6, 6), "-01")
  }
  else {
    city[[6]][[i]] <- paste0(substr(city[[6]][[i]], 1, 4), "-", substr(city[[6]][[i]], 6, 7), "-01")
  }
}


### Now, we set the working directory to the temporary directory 

setwd(tempdir())

file <- list.files(pattern = "*.nc")

### We will create the data frame that will store our results 

depart = 1

for (i in depart:length(file)) { # # we iterate on the files
  # we include the creation of the dataframe in the loop to reinitialize it to store results by month 
  data <- data.frame(matrix(vector(), 0, 3, dimnames=list(c())))
  colnames(data) <- c("City", "EST_PM25", "Time")
  
  
  # we load the file  
  ras <- raster(file[i])


  # we create the variable with the time, that we get from the filename 
  time <- paste0(substr(file[i], 24, 27), "-", substr(file[i], 28, 29))
  date <- paste0(substr(file[i], 24, 27), "-", substr(file[i], 28, 29), "-01")
  
  for (j in 1:length(city[[1]])) {  # we iterate over the cities
    
    # here, we choose to take only a city if the month of the file is in a specified range around the opening of the subway

    if (date > as.Date(city[[6]][[j]]) - 550 & date < as.Date(city[[6]][[j]]) + 550) {
    
      poly <- ls[[j]]
      nom <- city[[1]][[j]]
      gg <- extract(ras, poly)
      pollution <- mean(as.numeric(unlist(gg)), na.rm = T)
      
      # we merge it to the final dataframe 
      
      data[j,] <- c(nom, pollution, date)
       
    }

  }
  #data <- data[complete.cases(data),]
  # write the csv for the given file 
  write.csv(data, paste0(dir,"interm/data",time,".csv")) 
  
}

# NB : apparently, the example file that we gave were extracted without regard for the range of the date

