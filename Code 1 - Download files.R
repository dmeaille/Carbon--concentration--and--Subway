# @author : Davi Méaille
# Created : 01/10/2022
# Last modification : 01/10/2022
# Description : 
# 
# This file webscrapes the netcdf files containing the
# geographical data on the website displayed in the code.
# I resorted to the function BROWSE() in httr because, for
# reasons that I did not figure out, the files downloaded 
# with download.file() could not be opened, neither by 
# ncdf4::nc_open() nor raster::raster(). 
# The files are downloaded in the Downloads folder, but since 
# the project was originally to build a function with download.file()
# that would allow to read file from the internet without having 
# to download them, I still store the files in tempdir() to 
# imitate the behavior originally intended.

####################   DOWNLOAD THE FILE #################
####################                     #################

library(rvest)
library(httr)

########## Find the document to download 
download_time = Sys.time()

# We create the list where we will store the indexes of the files 
charter = list()

for (i in 1:6) {
  
  # First, we get the number of the files 
  
  url = paste0("https://m.box.com/shared_item/https%3A%2F%2Fwustl.box.com%2Fv%2FACAG-V5GL01-GWRPM25/browse/146850834632?page=", i)
  page = read_html(url)
  
  # for that, we need to find the href 
  list = page %>% html_element("body") %>% html_elements("a")
  
  # then, we cut in the relevant strings the characters that we want 
  
  charter = append(charter, lapply(list[6:(length(list)-9)], stringr::str_sub, start = 108, end = 119))
}




############ Launch the downloading process

lapply(charter, BROWSE, paste0("https://m.box.com/file/", charter, "/download?shared_link=https%3A%2F%2Fwustl.box.com%2Fv%2FACAG-V5GL01-GWRPM25"))


########### Move the file in the temporary directory 


dir = "C:/Users/davim/Downloads"

files = dir()[grep(".nc", dir())] # or dir()[file.mtime(dir()) > download_time] # to find only the recently downloaded files

lapply(files, file.copy,from = dir, to = tempdir()) # to put all the files in the temporary directory linked to this session
lapply(files, file.remove) # to delete them from the computer 


# NB : DO NOT CLOSE THE SESSION BEFORE RUNNING THE EXTRACTION OF CITIES VALUES, OTHERWISE THE FILES WILL BE DELETED

