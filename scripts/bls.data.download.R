
# Set main part of url for downloading the files
main.url <- "http://download.bls.gov/pub/time.series/la/"

# Set main directory for download
download.dir <- "~/spatial-analysis-in-r/data/bls/"

# List of files to download
file.list <- c("la.area", "la.area_type", "la.data.64.County",
               "la.area", "la.area.type", "la.measure", "la.measure",
               "la.period", "la.series", "la.state_region_division")

# combine download urls
download.urls <- unlist(lapply(main.url, FUN = "paste0", file.list))

# combine for file locations
download.locations <- unlist(lapply(download.dir, FUN = "paste0", file.list))

# download files
for (file in 1:length(file.list)) {
  download.file(url = download.urls[file], destfile = download.locations[file])
}


