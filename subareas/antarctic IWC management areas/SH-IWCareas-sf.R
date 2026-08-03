library(tidyverse)
library(sf)
library("rnaturalearth")
library("rnaturalearthdata")
ne_download(category = "physical", type="ocean", scale= 10, returnclass = "sf")

#### polygons of oceans ####
oceanshp <- "C:/Users/IsidoraKatara/OneDrive - International Whaling Commission/thirdpartydata/marineregions/Global Oceans and Seas/goas_v01.shp"
oceanpoly <- st_read(oceanshp)

#### mapping function ####
mappingf <- function(x){
  
  library("ggplot2")
  theme_set(theme_bw())
  
  areas_bbox <- st_bbox(x)
  x <- cbind(x, st_coordinates(st_centroid(x)))
  y <- ggplot() +
    geom_sf(data = x, fill = "lightblue", alpha=0.3) + 
    geom_sf(data = oceanpoly, fill = "lightgrey", alpha=0.3) +
    geom_text(data = x, aes(X, Y, label = subareas), size = 3, col = "red") +
    coord_sf(xlim = c(areas_bbox$xmin, areas_bbox$xmax), ylim = c(areas_bbox$ymin, areas_bbox$ymax), expand = T)
  print(y)
  return(y)
}

#create a df for the subareas (xy coordinates)
#multipolygon for subarea V because it crosses over longitude 180
df <- structure(list(
  geometry = c(
    "POLYGON ((-120 -60, -60 -60, -60 -90, -120 -90, -120 -60))",
    "POLYGON ((-60 -60, 0 -60, 0 -90, -60 -90, -60 -60))",
    "POLYGON ((0 -60, 70 -60, 70 -90, 0 -90, 0 -60))",
    "POLYGON ((70 -60, 130 -60, 130 -90, 70 -90, 70 -60))",
    "MULTIPOLYGON (((130 -60, 180 -60, 180 -90, 130 -90, 130 -60)), ((-170 -60, -170 -90, -180 -90, -180 -60, -170 -60)))",
    "POLYGON ((-170 -60, -120 -60, -120 -90, -170 -90, -170 -60))",
    "MULTIPOLYGON (((0 -60, 180 -60, 180 -90, 0 -90, 0 -60)), ((-180 -60, -180 -90, 0 -90, 0 -60, -180 -60)))"
), subareas = c('Area I','Area II','Area III','Area IV','Area V','Area VI',"Circumpolar-S of 60S")), 
row.names = c(NA, -7L), 
class = c("tbl_df", "tbl", "data.frame"))
df
sf <- sf::st_as_sf(df, wkt = "geometry", crs = 4326)
sf
plot(sf)

#plot to check with the world map
world <- ne_countries(scale = "medium", returnclass = "sf")
class(world)

#load the oceans 10m shapefile from NaturalEarth
oceans <- ne_load(category = "physical", type="ocean", scale= 10, returnclass = "sf")
sf_use_s2(FALSE)
#clip the polygons with the world using intersect (intersection of oceans and polygons)
output = st_intersection(sf, oceans) %>% mutate(accuracy = "accurate", survey = "IDCR/SOWER", large_area = c("SO","SO","SO","SO","SO","SO","SH"))

#plot the clipped subareas
mappingf(output)

# add the species column
Outlist <- list()
for (i in c("Ablu", "AMi", "Fin", "Hbk", "Spr","Srht")){
  Outlist[[i]] <- output %>% mutate(species = i)
}
out <- do.call("rbind",Outlist)
##############################

#save 
st_write(out, "C:/Users/IsidoraKatara/OneDrive - International Whaling Commission/Abundance-Tabs&Refs/Extras/mapping subareas/SH-IWCareas/SH-IWC-antarctic-areas.shp")
