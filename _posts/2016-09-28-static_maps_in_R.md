---
title: "Creating Static Maps for Manuscripts in R"
categories: blog
comments: true
date: "2016-09-28"
layout: post
tags: [R, maps, GIS]
---


## Frustration in Mapping

With so many tools and software options available to create maps and analyze spatial data, it's really not surprising that the hurdles required to learn how to use them can seem insurmountable. My first job out of college involved learning how to use ESRI's ArcGIS one painful hour after another. Eventually it became pretty straightforward to do many tasks, including making quality maps. It's a skill that required a lot of practice making awful maps, and having other people provide feedback (e.g., *constructively* telling you your maps suck). This process taught me a lot about not just how to use a spatial mapping software, but how to make something graphically pleasing, the importance of colors, fonts, font-sizes, etc. How a nice map can have a much greater influence on a reader and it can provide a much better way to convey data if done correctly.

Good thing this blog isn't going to really be about any of that. I'm writing this blog because I was recently quite frustrated with the awkward and we'll call it **[quasi-backwards compatability](http://imgs.xkcd.com/comics/workflow.png)** of non-open-source spatial software (*for example, ArcGIS...not that I'm pointing fingers*). I wanted to make a simple map. I started making it on one computer at work, and then when trying to open on a different computer, found I was unable to access that map because the versions were different. Sure, I *should have* followed a number of steps that would have allowed me to save to a previous version, which then could be read by both computers in question. Reality is, that didn't happen.

### Open Source Spatial Tools

Admittedly, I use ArcGIS because I have access to it, and the license fees are covered by my employers, and I've used it for years. It's comfortable. I know where to find things, how to make a nice map, and can usually do so in a fairly short amount of time. I know there are some great alternatives out there, namely **R** (the focus of this blog), and **QGIS**. I should and could use these options, but have just put it off because I didn't want to spend the time re-learning all the little tricks and tweaks I can do in ArcGIS. But this last experience pretty much lit a fire under me to see exactly how long it would take me to make a nice map (for a manuscript) in R. 

So how long did it take? Total hours was probably somewhere around 3-4 all said and done. I could have made the same map in about 20 minutes in ArcGIS. But now I have code, which I'm posting here so 
 - I can look it up again when I forget, and 
 - hopefully someone can save themselves some time and use this!

## R Spatial Packages

There are loads of spatial mapping/plotting packages in R, and I've used a number of them. But I wanted to stick with pipelines I was mostly familiar with, so I mainly focus on using ggplot2/tidyverse options here. These are the packages I ended up using, but there are certainly other options.


{% highlight r %}
suppressPackageStartupMessages(library(rgdal)) # spatial/shp reading
library(viridis) # nice color palette
library(ggplot2) # plotting
suppressPackageStartupMessages(library(ggmap)) # ggplot functionality for maps
library(ggsn) # for scale bars/north arrows in ggplots
library(maps)
library(mapdata)
suppressPackageStartupMessages(library(cowplot)) ## for arranging ggplots
{% endhighlight %}

## Get Data & Make it Spatial 

This is a subset of some data on study sites but it will suffice for our example. It has data in UTMs and as Lat/Longs, and columns with XY and `lat`/`lon` headers. Let's walk through reading this in, making it spatial, and reprojecting (or adding a projection). Projections are honestly the hardest part when dealing with spatial data, but once sorted it's pretty straightforward to make some maps! Just try to figure out what your spatial data is projected in and go from there. You can always convert between formats. Importantly, make sure you are always using `X/UTM_Easting/longitude` and `Y/UTM_Northing/latitude` columns and you know what [datum](https://en.wikipedia.org/wiki/Geodetic_datum) you are using (i.,NAD83, WGS84, etc).


{% highlight r %}
library(DT)
# read in data
sites<-read.csv("../data/Recsn_Sites_XY.csv", stringsAsFactors = FALSE)

DT::datatable(sites)
{% endhighlight %}

<img src="/img/Rfig/2016-09-28-static_maps_in_R.Rmd//get csv and makespatial-1.png" title="plot of chunk get csv and makespatial" alt="plot of chunk get csv and makespatial" width="100%" />

{% highlight r %}
# make this a spatial data frame (i.e., spatial data needs to be in numeric form (use UTM, lat/long, or X/Y columns, doesn't matter you can convert later). 

# use UTMS for now
sites.SP  <- SpatialPointsDataFrame(sites[,c(4,3)],sites[,-c(4,3)]) 

# Now data class SpatialPointsDataFrame but NO projection yet
# str(sites.SP) 
{% endhighlight %}

### Project and Re-project!

Importantly you'll need to know what your datum is if you want to convert or reproject to a standard that most mapping packages use (typically `WGS84`). To do so requires using something called `CRS` or the **Coordinate Reference System** which helps assign a datum, projection, and ellipsoid (earth curvature). Sometimes when you bring data (as in the case above where we read a csv in) in it doesn't have this information, and you need to assign a projection/datum. When reading in shapefiles, typically they will have this data already associated with them. Either way, we can check, and it's easy to change as needed. These `CRS` can be called using a unique code, called **EPSG**. For more than you could ever want, see [this page](http://spatialreference.org) or [this one](http://www.epsg-registry.org) for lists of codes, etc.


{% highlight r %}
## these are the CRS datum/projections "strings"
utms<-CRS("+proj=utm +zone=10 +datum=WGS84") # manual
utms # simplified but will work
{% endhighlight %}



{% highlight text %}
## CRS arguments:
##  +proj=utm +zone=10 +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0
{% endhighlight %}



{% highlight r %}
utms <- CRS("+init=epsg:32610") ## more detailed def using the EPSG code
utms # more detail
{% endhighlight %}



{% highlight text %}
## CRS arguments:
##  +init=epsg:32610 +proj=utm +zone=10 +datum=WGS84 +units=m +no_defs
## +ellps=WGS84 +towgs84=0,0,0
{% endhighlight %}



{% highlight r %}
proj4string(sites.SP)<-utms # add to the dataset

# now lets switch over data to long/lat and reproject
lats84<-CRS("+init=epsg:4326") # set the default for lat/longs
sites.SP<-spTransform(sites.SP, lats84)
proj4string(sites.SP) # double check data to make sure it has CRS
{% endhighlight %}



{% highlight text %}
## [1] "+init=epsg:4326 +proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
{% endhighlight %}

Ok! So we've pulled in a list of sites, could have come from field work, a GPS device, whatever. We converted from UTM to lat/lon & we projected this dataset into **`WGS84`** which is fairly universal (and easily plotted in things like *googlemaps, leaflet, Google Earth, etc.*).

Let's get a shapefile and read it in as well. For this I used a shapefile I created with major rivers draining from the Sierras and the San Joaquin/Sacramento Valley. I'm using the `rgdal` package here, but there are many that will read/work with shapefiles.


{% highlight r %}
rivers<- readOGR(dsn = "../data/", layer = "CentralValleyTribsAndRivs") # using rgdal
{% endhighlight %}



{% highlight text %}
## OGR data source with driver: ESRI Shapefile 
## Source: "../data/", layer: "CentralValleyTribsAndRivs"
## with 7729 features
## It has 28 fields
{% endhighlight %}



{% highlight r %}
# we can use ogrInfo to see CRS, attributes, etc.
ogrInfo(dsn="../data", layer="CentralValleyTribsAndRivs") # see shapefile info
{% endhighlight %}



{% highlight text %}
## Source: "../data", layer: "CentralValleyTribsAndRivs"
## Driver: ESRI Shapefile; number of rows: 7729 
## Feature type: wkbLineString with 2 dimensions
## Extent: (-221740.5 -305695.9) - (171829.4 366313)
## CRS: +proj=aea +lat_1=34 +lat_2=40.5 +lat_0=0 +lon_0=-120 +x_0=0 +y_0=-4000000 +datum=NAD83 +units=m +no_defs  
## LDID: 87 
## Number of fields: 28 
##          name type length typeName
## 1    OBJECTID    0      9  Integer
## 2      FNODE_    2     19     Real
## 3      TNODE_    2     19     Real
## 4      LPOLY_    2     19     Real
## 5      RPOLY_    2     19     Real
## 6      LENGTH    2     19     Real
## 7   HYDRARCA_    2     19     Real
## 8  HYDRARCA_I    2     19     Real
## 9      MAJOR1    2     19     Real
## 10     MINOR1    2     19     Real
## 11     MAJOR2    2     19     Real
## 12     MINOR2    2     19     Real
## 13     MAJOR3    2     19     Real
## 14     MINOR3    2     19     Real
## 15     MAJOR4    2     19     Real
## 16     MINOR4    2     19     Real
## 17     MAJOR5    2     19     Real
## 18     MINOR5    2     19     Real
## 19       FLOW    0      4  Integer
## 20     TDCKEY    0      9  Integer
## 21        DCU    0      9  Integer
## 22      PNAME    4     30   String
## 23      PNMCD    4     11   String
## 24  STATECODE    4      1   String
## 25     HSCKEY    0      9  Integer
## 26     HYSNUM    0      4  Integer
## 27    Element    4     50   String
## 28 Shape_Leng    2     19     Real
{% endhighlight %}



{% highlight r %}
proj4string(rivers) # check projection
{% endhighlight %}



{% highlight text %}
## [1] "+proj=aea +lat_1=34 +lat_2=40.5 +lat_0=0 +lon_0=-120 +x_0=0 +y_0=-4000000 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0"
{% endhighlight %}



{% highlight r %}
rivers<-spTransform(rivers, lats84) # add the projection so it matches
{% endhighlight %}

## Making a Basic Map!

Now that we spent some time figuring out our CRS and loading up some files, we can make a basic map using the `maps` and `mapsdata` packages. I'm using the `viridis` package to pull some nice colors for use in the map. Not necessary, but just throwing it out there. The basic plotting package is nice, and allows you to specify location and region (world wide or within US). I've limited to a specific lat and long range using the `xlim` and `ylim` functions.


{% highlight r %}
# Get a nice color palette to pull HEX color codes from
pal <- viridis_pal()(6)
# pal  "#440154FF" "#414487FF" "#2A788EFF" "#22A884FF" "#7AD151FF" "#FDE725FF"

# this is using the `maps` and `mapsdata` package
# start by plotting the state/county

map("state",region=c('CA'), xlim = c(-122.5,-119.5), ylim=c(38,40.5))
map.axes()
map("county",region=c('CA'),boundary=FALSE,lty=3,
    xlim = c(-122.5,-119.5), ylim=c(38,40.5), add=TRUE)
lines(rivers, col="#2A788EFF", lwd=1.1, xlim = c(-122.5,-119.5), ylim=c(38,40.5))

# add our point data from earlier
points(sites.SP, cex=1.4, pch=21, bg="#FDE725FF")

# add labels (using trial and error for placement)
text(sites.SP, labels=as.character(sites.SP@data$RIVER), col="gray20",
     cex=0.6, font=2, offset=0.5, adj=c(0,2))

# add a plot legend
legend("topright", border = "gray80",box.lwd = 1.5, box.col = "gray80",
       legend=c("Major Rivers", "Study Sites"),
       title="Study Map", bty="o", inset=0.05,
       lty=c( 1,-1,-1), pch=c(-1,21, 1), cex=0.8,
       col=c("#2A788EFF", "black"), pt.bg=c(NA, "#FDE725FF"))

# add a box for the scale bar
rect(-122.47, ybottom = 38.03, xright = -121.6, ytop = 38.4, col = "white", border = "transparent")

# add north arrows
library(GISTools)  
north.arrow(xb=-122.2, yb=38.5, len=0.07, lab="N", col="gray30",cex.lab = 0.9)
map.scale(xc = -122.05, yc=38.3, len=0.7, units = "km",subdiv = 5, sfcol = "white", ndivs = 3)
{% endhighlight %}

<img src="/img/Rfig/2016-09-28-static_maps_in_R.Rmd//basic map-1.svg" title="plot of chunk basic map" alt="plot of chunk basic map" width="100%" />

Ok, so it's basic, and things are a bit clustered up, but it's a decent map. There are ways to zoom to your study area, and you would probably want to play with the scale bar and north arrow a bit, but overall it's functional and was pretty easy to create. On to a fancier map using the ggplot framework!

## GGPLOT2 Map (`ggmap`)

Often we want to add a background to our map, some terrain, satellite imagery, et. Thankfully there are a number of easy options to do this using the ggmap package. We just need to assign a location, and appropriate zoom level. Using the `get_map` command we can take a look at several different types of layers, including *watercolor, toner, terrain, and satellite*. The `cowplot` package is a great way to plot/arrange ggplots.


{% highlight r %}
library(ggmap)
library(cowplot) # to make multiple plots

location=c(-120.9,39.24) # set the center of the map

map1 <- get_map(location=location,crop = F,
             color="bw",
             maptype="terrain",
             source="google",
             zoom=8)

map2 <- get_map(location=location,crop = F,
            maptype="toner",# toner-background is this with no cities
            source="stamen",
            zoom=7)

map3 <- get_map(location=location,crop = F,
             maptype="watercolor",
             source="stamen",
             zoom=7)

map4 <- get_map(location=location,crop = F,
             maptype="hybrid",
             source="google",
             zoom=7)

plot_grid(ggmap(map1), ggmap(map2), 
          ggmap(map3), ggmap(map4), 
          labels = c("Terrain","Toner","Watercolor","Satellite"),
          ncol = 2, align = 'v',label_size = 10)
{% endhighlight %}

<img src="/img/Rfig/2016-09-28-static_maps_in_R.Rmd//backgroundlayer ggmaps-1.svg" title="Four different background types using `ggmap`" alt="Four different background types using `ggmap`" width="100%" />

Once we have settled on an appropriate background, we can move forward with our ggmap. When using shapefiles or spatial data in ggplot, the structure is slightly different. Importantly you'll need to `fortify()` your spatial data so ggplot can read/plot it. Also, typically you need to specify the `group` and `fill` commands in the `aes()` call. 


{% highlight r %}
sitemap <- ggmap(map1, extent = 'device') # use the BW terrain option
rivers_df <- fortify(rivers) # make our river data spatial for ggplot

# notice we can just use the dataframe "sites" below with the lon/lat columns (since I know they are in WGS84). If we wanted to use the sites.SP we would need to fortify first.

nicemap<-
  sitemap + 
  labs(x="Longitude (WGS84)", y="Latitude") + 
  geom_path(data=rivers_df, aes(long, lat, group=group, fill=NULL), 
            color="#2A788EFF", alpha=0.7) + 
  geom_label(data=sites, aes(x=lon, y=lat, label=RIVER), 
             nudge_x=0.17, nudge_y=0.05, label.size=0.1,size=3, 
             fontface = "bold.italic", label.r=unit(0.20, "lines"))+
  geom_point(data=sites, aes(x=lon, y=lat), pch=21, size=4, fill="#FDE725FF")+
  theme_bw()+
  theme(panel.border = element_rect(colour = "black", fill=NA, size=1))

nicemap
{% endhighlight %}

<img src="/img/Rfig/2016-09-28-static_maps_in_R.Rmd//ggmap-1.svg" title="plot of chunk ggmap" alt="plot of chunk ggmap" width="100%" />

{% highlight r %}
# To save plot
# ggsave(filename = "./figs/site_map_ggplot.png", width = 6, height = 6, units = "in", dpi = 300)
{% endhighlight %}

## Adding the Pieces Together

A nice map should always have a north arrow and scale bar (in my opinion). Labels should be clear. It's also nice to have some sort of inset so you can figure out where the map fits in the big picture. So let's do that below! So close...this is the part that takes a bit of tweaking, but it's pretty quick once you have the code set up. I'm using the `ggsn` package below to add the North arrow and scale bar. To add the overview map, I'm wrapping the map/mapdata commands in a `map_data` function to make it a ggmap. Unforunately there seems to be a glitch in the north arrow function, and I can't pass that plot to the next step as a ggplot/ggmap object. It works, but it's the end point if using the `ggsn` package.


{% highlight r %}
# To figure out the bounding box max and mins
# attr(map1, "bb")

fmap<-
  sitemap + 
  labs(x="Longitude (WGS84)", y="Latitude") + 
  geom_path(data=rivers_df, aes(long, lat, group=group, fill=NULL), 
            color="#2A788EFF", alpha=0.7) + 
  geom_point(data=sites, aes(x=lon, y=lat), pch=21, size=4, fill="#FDE725FF")+
  geom_label(data=sites, aes(x=lon, y=lat, label=RIVER), 
             nudge_x=0.17, nudge_y=0.05, label.size=0.1,size=3, 
             fontface = "bold.italic", label.r=unit(0.20, "lines"))+
  theme_bw()+
  theme(panel.border = element_rect(colour = "black", fill=NA, size=1))

# using the ggmap bounding box to get the extent for the scale bar
finalmap <- fmap + scalebar(x.min = attr(map1, "bb")[[2]], 
           y.min=attr(map1, "bb")[[1]], 
           x.max =attr(map1, "bb")[[4]], 
           y.max=attr(map1, "bb")[[3]], 
           dist = 25, anchor = c(x=-122.1, y=38.0), 
           dd2km = T, model = 'WGS84', location = "topleft", st.size = 3.3, st.dist = 0.02)

# Issues with adding a North Arrow: need to use north2 with empty ggplot() calls, otherwise north()...this works but can't save it as a ggplot object

# svg(filename = "sitemap_northarrow.svg", width=6, height=6)
# north2(finalmap, x = 0.8, y=0.15, scale = 0.08, symbol = 12)
# dev.off()
{% endhighlight %}

![sitemapwarrow](../img/sitemap_northarrow.svg)


**Now let's add an inset map and arrange things:**


{% highlight r %}
# start by plotting the state/county as we did above
CA<-map_data("state",region=c('california'));
CAcounty<-map_data("county",region=c('CA'),boundary=FALSE,lty=3, col="gray30",add=TRUE)

# Make the Overview Map
overviewmap<-ggplot() + 
  geom_polygon(data=CA, aes(long, lat, group=group), 
               color="black", fill=NA) +
  geom_polygon(data=CAcounty, aes(long, lat, group=group), 
               color="gray50", fill=NA, linetype=3)+
  geom_point(aes(x = -120.9, y=39.2), size=4, # this is where sites are
             pch=23, col="gray40", bg="red")+
  coord_equal()+
  theme(plot.background =
          element_rect(fill = "white", linetype = 1,
                       size = 0.3, colour = "black"),
        axis.line=element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        legend.position="none")

# Use cowplot `draw_plot`:
  # draw_plot( x, y, width, height)
    # x: The x location of the lower left corner of the plot.
    # y: The y location of the lower left corner of the plot.
    # width, height: the width and the height of the plot

ggdraw() + 
  draw_plot(finalmap, 0, 0, 1, 1) +
  draw_plot(overviewmap, 0.72,0.72,0.25,0.25)

# ggsave(filename = "./img/site_map_inset.svg", width = 6, height = 6, units = "in", dpi = 300)
{% endhighlight %}

And the final product should look something like this, which is decent, not great but hope it's useful!

![sitemap](../img/site_map_inset.svg)
