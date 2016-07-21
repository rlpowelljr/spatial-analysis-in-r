## ----setup, include=FALSE------------------------------------------------
knitr::opts_chunk$set(fig.width = 9, fig.height = 9, fig.path = "figures/")

## ----directorySetup------------------------------------------------------
# Main directory
main.dir <- "~/spatial-analysis-in-r/"

# Script directory
script.dir <- paste0(main.dir, "scripts/")

# data directory
dat.dir <- paste0(main.dir, "data/")

## ----loadPackages, warning = FALSE, error = FALSE, message = FALSE-------
# data import
library(openxlsx)

# data cleaning
library(dplyr)
library(magrittr)
library(stringr)

# general plotting
library(ggplot2)

# mapping
library(sp)
library(rgdal)
library(GISTools)

# distance calculation
library(geosphere)

## ----blsDataPrep1--------------------------------------------------------
# Import UE Data
fname <- paste0(dat.dir, "/bls/la.data.64.County")
bls.dat <- read.delim(fname, header = TRUE, stringsAsFactors = FALSE, 
                      sep = "\t")

# trim white space in series_id
bls.dat$series_id <- trimws(bls.dat$series_id)

# change value to numeric
bls.dat$value <- as.numeric(bls.dat$value)

head(bls.dat)

## ----blsDataPrep2--------------------------------------------------------
# Import la.measure
fname <- paste0(dat.dir, "/bls/la.measure")
bls.measure <- read.delim(fname, header = TRUE, stringsAsFactors = FALSE, 
                      sep = "\t")

## ----blsDataPrep3--------------------------------------------------------
# fix variables
bls.measure$measure_text <- bls.measure$measure_code
bls.measure$measure_code <- as.numeric(rownames(bls.measure))

bls.measure

## ----blsDataPrep4--------------------------------------------------------
# la.period
fname <- paste0(dat.dir, "/bls/la.period")
bls.period <- read.delim(fname, header = TRUE, stringsAsFactors = FALSE, 
                      sep = "\t")

bls.period

## ----blsDataPrep6--------------------------------------------------------
# la.period
fname <- paste0(dat.dir, "/bls/la.series")
bls.series <- read.table(fname, header = TRUE, stringsAsFactors = FALSE, 
                      sep = "\t")

# trim white space from series_id
bls.series$series_id <- trimws(bls.series$series_id)

head(bls.series)

## ----blsDataPrep7--------------------------------------------------------
# filter for period M13
bls.dat <- bls.dat[bls.dat$period == "M13",]

# filter for year
bls.dat <- bls.dat[bls.dat$year %in% c(2011:2015),]
 
# Join data together via a left join.
bls.dat <- merge(bls.dat, bls.series,
                 by.x = "series_id", by.y = "series_id",
                 all.x = TRUE)

bls.dat <- merge(bls.dat, bls.measure,
                 by.x = "measure_code", by.y = "measure_code", all.x = TRUE)

# filter for unemployment rate
bls.dat <- bls.dat[bls.dat$measure_text == "unemployment rate", ]

# reduce dataset
bls.dat <- bls.dat[, c("series_id", "year", "value", 
                       "series_title", "measure_text")]

# Create county name and state variables for easier identification
str.pattern <- "[A-za-z.//]*\\s*[A-za-z.//]*\\s*[A-Za-z.//]*,"

bls.dat$county <- str_extract(bls.dat$series_title, str.pattern)

bls.dat$county <- trimws(gsub(",", "", bls.dat$county))

bls.dat$state <-  str_extract(bls.dat$series_title, "[A-Z]{2}")

# Extract FIPS Code
bls.dat$FIPS <- substr(bls.dat$series_id, 6, 10)

# Select columns
bls <- bls.dat[c("FIPS", "county", "state", "year", "value")]

# Change names
names(bls) <- c("FIPS", "county", "state", "year", "UE")

## ----blsDataPrep8--------------------------------------------------------
head(bls)
summary(bls)

## ----airportPrep---------------------------------------------------------
fname <- paste0(dat.dir, "airports/airports.dat.txt")
airports <- read.csv(fname, header = TRUE, stringsAsFactors = FALSE)

summary(airports)
head(airports)

## ----faaPrep-------------------------------------------------------------
fname <- paste0(dat.dir, "faa/CY12AllEnplanements.xlsx")
faa.cy12 <- openxlsx::read.xlsx(fname)

fname <- paste0(dat.dir, "faa/cy13-all-enplanements.xlsx")
faa.cy13 <- openxlsx::read.xlsx(fname)

fname <- paste0(dat.dir, "faa/CY14-all-enplanements.xlsx")
faa.cy14 <- openxlsx::read.xlsx(fname, sheet = "data")

fname <- paste0(dat.dir, "faa/preliminary-cy15-all-enplanements.xlsx")
faa.cy15 <- openxlsx::read.xlsx(fname)

# Select Annual Data, Rename columns, and add year.
faa.cy11 <- faa.cy12[, c("ST", "Locid", "City", "Airport.Name", 
                         "CY.11.Enplanements")]
names(faa.cy11) <- c("state", "id", "city", "airport.name", "enplanements")
faa.cy11$year <- 2011

faa.cy12 <- faa.cy12[, c("ST", "Locid", "City", "Airport.Name", 
                         "CY.12.Enplanements")]
names(faa.cy12) <- c("state", "id", "city", "airport.name", "enplanements")
faa.cy12$year <- 2012

faa.cy13 <- faa.cy13[, c("ST", "Locid", "City", "Airport.Name",
                         "CY.13.Enplanements")]
names(faa.cy13) <- c("state", "id", "city", "airport.name", "enplanements")
faa.cy13$year <- 2013

faa.cy14 <- faa.cy14[, c("ST", "Locid", "City", "Airport.Name",
                         "CY.14.Enplanements")]
names(faa.cy14) <- c("state", "id", "city", "airport.name", "enplanements")
faa.cy14$year <- 2014

faa.cy15 <- faa.cy15[, c("ST", "Locid", "City", "Airport.Name",
                         "CY.15.Enplanements")]
names(faa.cy15) <- c("state", "id", "city", "airport.name", "enplanements")
faa.cy15$year <- 2015

# Combine
faa <- rbind(faa.cy11, faa.cy12, faa.cy13, faa.cy14, faa.cy15)

summary(faa)
head(faa)

## ----shapefileImport-----------------------------------------------------
dsn <- "/Users/Robby/spatial-analysis-in-r/data/census/"
layer <- "tl_2015_us_county"
county <- rgdal::readOGR(dsn = dsn, layer = layer)

## ----plotLimitsCONUS-----------------------------------------------------
# Continental US (CONUS)
conus.min.lat <- 25
conus.max.lat <- 50
conus.min.long <- -126
conus.max.long <- -65

conus.long.limits <- c(conus.min.long, conus.max.long)
conus.lat.limits <- c(conus.min.lat, conus.max.lat)

## ----plotLimitsHawaii----------------------------------------------------
# Hawaii
hawaii.min.lat <- 18
hawaii.max.lat <- 23
hawaii.min.long <- -161 
hawaii.max.long <- -154

hawaii.long.limits <- c(hawaii.min.long, hawaii.max.long)
hawaii.lat.limits <- c(hawaii.min.lat, hawaii.max.lat)

## ----plotLimitsAlaska----------------------------------------------------
# Alaska
alaska.min.lat <- 52
alaska.max.lat <- 72
alaska.min.long <- -177
alaska.max.long <- -129

alaska.long.limits <- c(alaska.min.long, alaska.max.long)
alaska.lat.limits <- c(alaska.min.lat, alaska.max.lat)

## ----countyAirportIdentification1----------------------------------------
# filter airport coordinates based on FAA codes in faa.data
airports <- airports[airports$country == "United States",]

#filter for CONUS, AK, and HI airports for plotting purposes-only
airports2 <- 
  airports[(between(airports$latitude, conus.min.lat, conus.max.lat) &
           between(airports$longitude, conus.min.long, conus.max.long)) |
           (between(airports$latitude, hawaii.min.lat, hawaii.max.lat) &
           between(airports$longitude, hawaii.min.long, hawaii.max.long)) |
           (between(airports$latitude, alaska.min.lat, alaska.max.lat) &
           between(airports$longitude, alaska.min.long, alaska.max.long)),]

# Prep airport coordinates
coordinates(airports) <- c("longitude", "latitude")
proj4string(airports) <- proj4string(county)

coordinates(airports2) <- c("longitude", "latitude")
proj4string(airports2) <- proj4string(county)

# Set layout for image.
layout(matrix(c(1,1,1,1,
                1,1,1,1,
                2,2,3,3,
                2,2,3,3), ncol = 4, nrow = 4, byrow = TRUE),
       respect = TRUE)

# CONUS Plot (Plot 1)
plot(county, xlim = conus.long.limits, ylim = conus.lat.limits,
     main = "Plot of Airports and Counties", border = "grey",
     lwd = 0.25)
points(airports2, xlim = conus.long.limits, ylim = conus.lat.limits,
       pch = 20, cex = 0.5)

# Hawaii Plot (Plot 2)
plot(county, xlim = hawaii.long.limits, ylim = hawaii.lat.limits,
     border = "grey", lwd = 0.25)
points(airports2, xlim = hawaii.long.limits, ylim = hawaii.lat.limits,
       pch = 20)

# Alaska Plot (Plot 3)
plot(county, xlim = alaska.long.limits, ylim = alaska.lat.limits,
     border = "grey", lwd = 0.25)
points(airports2, xlim = alaska.long.limits, ylim = alaska.lat.limits,
       pch = 20)

## ----countyAirportIdentification2----------------------------------------
# get county ID
airports$county.id <- 
  sp::over(airports, county)$GEOID

# look at results
head(airports)

## ----distCalc------------------------------------------------------------
# Set up output data frame
apt.dist.dat <- data.frame(county.id = county$GEOID,
                           stringsAsFactors = F)

# Calculate distance between each airport
# NOTE: Consider building function instead of looping.
for (apt in airports$airport.id) {
  # The id is created such that the numbers will not make R think it is
  # creating column number XXX vice just adding a new column.
  apt.id <- paste0("airport.", apt)
  
  # get coordinates for airports and counties
  apt.coords <- coordinates(airports)[airports$airport.id == apt,]
  county.coords <- coordinates(county)
  
  # calculate distance
  apt.dist.dat[, apt.id] <- distHaversine(apt.coords, county.coords)
}

## ----distCalcMin---------------------------------------------------------

# This function will return the minimum distance.
min.dist.fn <- function(temp) {

  # Select airport with smallest distance
  min.index <- which.min(temp)
  
  # Return distance
  min.dist <- temp[min.index]
  
  # Get airport ID
  apt.id <- names(temp)[min.index]
  
  # output data
  out <- cbind(min.dist, apt.id)
  return(out)
}

# Get counties
counties <- apt.dist.dat$county.id
# Get minimum distance
min.dist <- apply(apt.dist.dat[,-1], MARGIN = 1, FUN = min.dist.fn)

# transpose and convert from list
min.dist <- t(unlist(min.dist))

# create data frame
min.dist <- data.frame(min.dist, stringsAsFactors = F)

# give column names
names(min.dist) <- c("min.distance", "airport.id")

# convert min.dist to miles
min.dist$min.distance <- as.numeric(min.dist$min.distance)/1609.34

# Get airport ID number
min.dist$airport.id <- gsub("airport.", "", min.dist$airport.id)

# create final distance data set.
cnty.dist <- cbind(counties, min.dist)

cnty.dist$counties <- as.character(cnty.dist$counties)
# look at resulting data set
summary(cnty.dist)
head(cnty.dist)

## ----distPlot------------------------------------------------------------
# Set layout for image.
layout(matrix(c(1,1,1,1,
                1,1,1,1,
                2,2,3,3,
                2,2,3,3), ncol = 4, nrow = 4, byrow = TRUE),
       respect = TRUE)

# create plot dat
plt.dat <- cnty.dist[order(cnty.dist$counties),]

# Create shading
shading <- GISTools::auto.shading(plt.dat$min.distance, n = 5, cols = brewer.pal(5, "Blues"))

# CONUS Plot (Plot 1)
choropleth(county, plt.dat$min.distance, shading = shading,
           xlim = conus.long.limits, ylim = conus.lat.limits,
           main = "Plot of Min Distance to Airport", border = NA)
# add legend
choro.legend(px = -125, py = 31, sh = shading)

# Hawaii Plot (Plot 2)
choropleth(county, plt.dat$min.distance, shading = shading,
     xlim = hawaii.long.limits, ylim = hawaii.lat.limits,
     border = NA)

# Alaska Plot (Plot 3)
choropleth(county, plt.dat$min.distance, shading = shading,
     xlim = alaska.long.limits, ylim = alaska.lat.limits,
     border = NA)


## ----finalAnalysisData---------------------------------------------------
# join BLS data and cnty.dist dat
analysis.dat <- merge(bls, cnty.dist,
                      by.x = "FIPS", by.y = "counties", 
                      all.x = TRUE)

# join airports with analysis.dat
analysis.dat <- merge(analysis.dat, 
                      airports[, c("airport.id", "iata.faa.code", "county.id")],
                      by.x = "airport.id", by.y = "airport.id", all.x = TRUE)

# join with faa data
analysis.dat <- merge(analysis.dat, faa[, c("id", "year", "enplanements")],
                      by.x = c("iata.faa.code", "year"),
                      by.y = c("id", "year"), all.x = TRUE)

# determine if airport located within county
analysis.dat$airport.in.cnty <- 
    ifelse(analysis.dat$FIPS == analysis.dat$county.id, 1, 0)


# select and reorder remaining variables
vars <- c("FIPS", "county", "state", "year", "UE", "min.distance", 
          "enplanements", "airport.in.cnty")

analysis.dat <- analysis.dat[, vars]

# look at data
dim(analysis.dat)
summary(analysis.dat)
head(analysis.dat)

# show complete cases
dim(analysis.dat[complete.cases(analysis.dat),])
summary(analysis.dat[complete.cases(analysis.dat),])
head(analysis.dat[complete.cases(analysis.dat),])


## ----EDA1----------------------------------------------------------------
# Unemployment Data
ggplot(analysis.dat[!is.na(analysis.dat$year),]) +
  aes(year, UE, group = year) +
  geom_boxplot() +
  xlab("Year") + ylab("Unemployment") +
  ggtitle("Unemployment by Year")

## ----EDA2----------------------------------------------------------------

ggplot(analysis.dat) +
  aes(year, enplanements, group = year) +
  geom_boxplot() +
  xlab("Year") + ylab("Enplanements") +
  ggtitle("Enplanements by Year")

## ----EDA3----------------------------------------------------------------
ggplot(analysis.dat[analysis.dat$enplanements < 250000,]) +
  aes(year, enplanements, group = year) +
  geom_boxplot() +
  xlab("Year") + ylab("Enplanements") +
  ggtitle("Enplanements by Year")


## ----EDA4----------------------------------------------------------------
ggplot(analysis.dat) +
  aes(year, min.distance, group = year) +
  geom_boxplot() +
  xlab("Year") + ylab("Minimum Distance (mi)") +
  ggtitle("Minimum Distance to Nearest Airport by Year")

ggplot(analysis.dat[analysis.dat$min.distance < 900,]) +
  aes(year, min.distance, group = year) +
  geom_boxplot() +
  xlab("Year") + ylab("Minimum Distance (mi)") +
  ggtitle("Minimum Distance to Nearest Airport by Year")

hist(analysis.dat$min.distance, 
     main = "Histogram of Minimum Distance")

hist(analysis.dat$min.distance[analysis.dat$min.distance < 900],
     main = "Histogram of Minimum Distance to Airport < 900mi")


## ----EDA_pairs-----------------------------------------------------------
pairs(analysis.dat[c("year", "UE", "min.distance", "enplanements", 
                     "airport.in.cnty")])

ggplot(analysis.dat) +
  aes(x = UE, y = log10(enplanements)) +
  geom_point() +
  xlab("UE") + ylab("log10(enplanements)")

ggplot(analysis.dat) +
  aes(x = UE, y = min.distance) +
  geom_point() +
  xlab("UE") + ylab("min.distance")
  
ggplot(analysis.dat) +
  aes(x = UE, y = airport.in.cnty) +
  geom_point() +
  xlab("UE") + ylab("airport.in.cnty")


## ----EDA_corrs-----------------------------------------------------------
cor.test(analysis.dat$UE, analysis.dat$min.distance)

cor.test(analysis.dat$UE, analysis.dat$enplanements)


## ----qqplots1------------------------------------------------------------
qqnorm(analysis.dat$UE)
qqline(analysis.dat$UE)

## ----qqplots2------------------------------------------------------------
qqnorm(analysis.dat$min.distance)
qqline(analysis.dat$min.distance)

## ----qqplots3------------------------------------------------------------
qqnorm(analysis.dat$enplanements)
qqline(analysis.dat$enplanements)

## ----model---------------------------------------------------------------

model <- lm(log(UE) ~ min.distance + enplanements + airport.in.cnty,
            data = analysis.dat)


## ----model_summary-------------------------------------------------------
model
summary(model)
anova(model)

layout(matrix(c(1,2,3,4),2,2))
plot(model)

## ----computerInfo--------------------------------------------------------
sessionInfo()

## ----appendixA, eval = FALSE---------------------------------------------
## # PLACE HOLDER FOR CODE HERE
## 
## # NEED TO SPIN RMD DOCUMENT AND DELETE APPENDIX CODE BEFORE PASTING
## 

## ----appendixB, eval = FALSE---------------------------------------------
## # File url
## file <- "https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat"
## 
## # destination
## dest <- "~/spatial-analysis-in-r/data/airports/airports.dat.txt"
## 
## # download file
## download.file(file, dest)
## 
## # Check downloaded file
## airports <- read.csv(dest, header = FALSE)
## 
## # name columns
## names(airports) <- c("airport.id", "name", "city", "country", "iata.faa.code",
##                      "icao.code", "latitude", "longitude", "altitude",
##                      "UTC.offset", "DST", "time.zone.olson")
## 
## # save file with column names
##   write.csv(airports, dest, row.names = FALSE)

## ----appendixC, eval = FALSE---------------------------------------------
## # County shapefile url
## url <- "ftp://ftp2.census.gov/geo/tiger/TIGER2015/COUNTY/tl_2015_us_county.zip"
## 
## # path
## path <- "~/spatial-analysis-in-r/data/census/"
## 
## # destination
## dest <- paste0(path, "tl_2015_us_county.zip")
## 
## # download file
## download.file(url, dest)
## 
## # unzip file
## unzip(dest, exdir = path, junkpaths = TRUE)

## ----appendixD, eval = FALSE---------------------------------------------
## 
## # Set main part of url for downloading the files
## main.url <- "http://download.bls.gov/pub/time.series/la/"
## 
## # Set main directory for download
## download.dir <- "~/spatial-analysis-in-r/data/bls/"
## 
## # List of files to download
## file.list <- c("la.area", "la.area_type", "la.data.64.County", "la.measure",
##                "la.period", "la.series", "la.state_region_division")
## 
## # combine download urls
## download.urls <- unlist(lapply(main.url, FUN = "paste0", file.list))
## 
## # combine for file locations
## download.locations <- unlist(lapply(download.dir, FUN = "paste0", file.list))
## 
## # download files
## for (file in 1:length(file.list)) {
##   if (!(file.list[file] %in% dir(download.dir))) {
##     download.file(url = download.urls[file], destfile = download.locations[file])
##   }
## }

