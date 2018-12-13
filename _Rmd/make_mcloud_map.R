# mcloud map
library(mapview); library(sf); library(tidyverse)

utm_e <- c(0566122, 0565284)
utm_n <- c(4538006, 4534136)
site <- c("140", "119")

df <- tibble("X"=utm_e, "Y"=utm_n, "sites"=site)

df_sf <- st_as_sf(df, coords=c("X","Y"), remove = F, crs=32610) %>% st_transform(4326)

maplays <- c("Esri.WorldTopoMap","Esri.WorldImagery","CartoDB.Positron","OpenTopoMap", "OpenStreetMap")

mapview(df_sf, map.types=maplays)

