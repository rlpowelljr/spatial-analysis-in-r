# County shapefile url
url <- "ftp://ftp2.census.gov/geo/tiger/TIGER2015/COUNTY/tl_2015_us_county.zip"

# path
path <- "~/spatial-analysis-in-r/data/census/"

# destination
dest <- paste0(path, "tl_2015_us_county.zip")

# download file
download.file(url, dest)

# unzip file
unzip(dest, exdir = path, junkpaths = TRUE)
