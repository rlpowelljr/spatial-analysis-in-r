# File url
file <- "https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat"

# destination
dest <- "~/spatial-analysis-in-r/data/airports/airports.dat.txt"

# download file
download.file(file, dest)

# Check downloaded file
airports <- read.csv(dest, header = FALSE)

# name columns
names(airports) <- c("airport.id", "name", "city", "country", "iata.faa.code",
                     "icao.code", "latitude", "longitude", "altitude",
                     "UTC.offset", "DST", "time.zone.olson")

# save file with column names
  write.csv(airports, dest, row.names = FALSE)