---
categories: blog
comments: true
use-site-title: false
date: "2019-09-17"
layout: post
tags: [R, spatial, database]
output: 
  html_document:
    code_folding: hide
---

Reading databases of different types is always fun. I have to look it up each time, and now that there are many different options, it makes things even more exciting. Add that I work across both PC and OSX platforms, and the excitement can quickly become frustration. 

But fear not! The R environment is rich with tools, and I probably only touch on a small proportion of them, but there are some great options for working with databases in R. I wanted to write a short post on how you can interact/read/write to a few of the more common databases using R. Mainly I wanted to put all the code in one single place so I can refer to it in the future :)

I'll try to cover both spatial and non-spatial options, and largely focus on a 4 main types of databases:

 - SQLite (**`.sqlite`**)
 - Geopackages (a spatial sqlite, **`.gpkg`**)
 - Access Databases (both **`.mdb`** and **`.accdb`**)
 - Geodatabases (often used by ESRI ArcGIS, **`.gdb`**)

## Database Types

Let's **load the libraries** we're going to need first. The main libraries you'll need are the excellent [`Hmisc`](https://github.com/harrelfe/Hmisc) package (good for opening Access DB), `dplyr` (helful for most sqlite DB and wrangling data), and [`sf`](https://r-spatial.github.io/sf/). The other packages below are largely for additional plotting/utility.


{% highlight r %}
library(Hmisc) # opening Access .mdb
library(dplyr) # opening .sqlite
library(RSQLite) # opening sqlite
library(sf) # spatial everything, gpkg and gdb's
library(here) # helpful for directories

# plotting
library(mapview)
{% endhighlight %}




For this post, we'll be using data/databases created from an [ecological dataset from the Chihuahuan Desert](http://esapubs.org/archive/ecol/E090/118/metadata.htm). This dataset is great for learning, and has been used extensively in the [Data Carpentry Ecology lessons](https://datacarpentry.org/ecology-workshop/), and I've modified and created an Access, SQLite and csv version of the dataset. These data are available for download [here](https://github.com/ryanpeek/ryanpeek.github.io/tree/master/data/portal_db).

## Opening Access Databases (`.mdb` & `.accdb`)

While using Access may seem daunting, it's a very stable and common way to both enter and store data. We use these databases for biological data, and they are fairly stable, despite some idiosyncrasies.  To open an `.mdb/.accdb` Access database in R, we can use the `Hmisc` package as follows to connect to an Access database, and show what tables are in the database:


{% highlight r %}
# path to .mdb database
mdb_path <- paste0(here(), "/data/portal_db/portal_sample.accdb")
mdb.get(mdb_path, tables=TRUE)
{% endhighlight %}



{% highlight text %}
## [1] "Plots"    "Plots_xy" "Species"  "Surveys"
{% endhighlight %}

Next we can use `mdb.get` to actually pull these tables into R:


{% highlight r %}
# get plot data:
plots <- mdb.get(mdb_path, tables = "Plots")

# get plot data with lat/lon info
plots_xy <- mdb.get(mdb_path, tables = "Plots_xy")

# species data
species <- mdb.get(mdb_path, tables = "Species")
DT::datatable(species) # show a table of data
{% endhighlight %}

<img src="/img/Rfig/2019-09-17-reading-databases-in-R.Rmd//mdgGet-1.png" title="plot of chunk mdgGet" alt="plot of chunk mdgGet" width="100%" />

{% highlight r %}
# surveys data
surveys <- mdb.get(mdb_path, tables = "Surveys")
{% endhighlight %}

### Fancy `.accdb`

Sometimes there are `.accdb` databases which are fancy. They have lots of cool options and have been designed to do *a lot*. I've run into issues trying to open these or access them in R. One potential work around is to split the database into a front end and backend. In this case, the front-end is essentially the queries, reporting, and forms, and the backend is the datatables.

<img src="//Users/ryanpeek/Documents/github/WEBSITES/ryanpeek.github.io/img/mullet_party.jpg" title="plot of chunk mullet" alt="plot of chunk mullet" width="50%" />


There's [an article here](https://support.office.com/en-us/article/split-an-access-database-3015ad18-a3a1-4e9c-a7f3-51b1d73498cc) which describes how this process works, and how you can do it. I will say I've tried this with a fancy database at work, and I've been able to read in the backend (the `.accdb` that has the data tables) without any trouble. 


## Opening SQLite DB

The good news is SQLite databases are easy to work with, they are open-source and cross-platform compatible, and you can open them with a few different packages in R.

### Using `RSQLite`

Here's a quick example of how to read an `sqlite` version of the portals database using `RSQLite`.


{% highlight r %}
# using RSQLite
library(RSQLite)

# make a relative path to your database using the here::here() function
dbpath <- paste0(here(), "/data/portal_db/portal_db.sqlite")

# actually connect to the database
dbcon <- dbConnect(dbDriver("SQLite"), dbpath)

# list all the tables in the database:
dbListTables(dbcon)
{% endhighlight %}



{% highlight text %}
## [1] "plots"        "plots_xy"     "species"      "sqlite_stat1"
## [5] "sqlite_stat4" "surveys"
{% endhighlight %}



{% highlight r %}
# disconnect with database
dbDisconnect(dbcon)
{% endhighlight %}

### Using `dplyr`

And here's how to to do the same thing with `dplyr`. Note the argument that specifies `create=FALSE`, so we don't create/overwite an existing database.


{% highlight r %}
dbpath <-paste0(here(), "/data/portal_db/portal_db.sqlite") # path to DB

dbcon <- src_sqlite(dbpath, create = FALSE) # to open but not create a DB

src_tbls(dbcon) # see tables in DB
{% endhighlight %}



{% highlight text %}
## [1] "plots"        "plots_xy"     "species"      "sqlite_stat1"
## [5] "sqlite_stat4" "surveys"
{% endhighlight %}

### Collect Tables from SQLite

To pull a table from either of the above connection options (`RSQLite` or `dplyr`), we can use the `tbl()` and `collect` functions in dplyr.


{% highlight r %}
# collect a table
plots <- tbl(dbcon, "plots") %>% collect()

# preview the table
glimpse(plots)
{% endhighlight %}



{% highlight text %}
## Observations: 24
## Variables: 2
## $ plot_id   [3m[38;5;246m<int>[39m[23m 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,…
## $ plot_type [3m[38;5;246m<chr>[39m[23m "Spectab exclosure", "Control", "Long-term Krat Exclos…
{% endhighlight %}


## Spatial Databases (Geopackage `gpkg` & `GDB`)

I wrote a post on geopackage and [how great it is here](https://ryanpeek.github.io/mapping-in-R-workshop/spatial_export_import_gpkg.html), so be sure to check it out. It's essentially a spatial sqlite database, and it's a great option for working with spatial data (including both vector and raster datatypes). An extra perk is that you can store simple flat tables, csvs, etc in a geopackage just as you would in access or sqlite, but with the added benefit that should you want to keep spatial data too, you can.

To connect and access geopackage data, we'll want to use the `sf` package. For this example I'm using the dataset from my previous post, which you can [download here](https://github.com/ryanpeek/mapping-in-R-workshop/raw/master/data/gpkg_in_R_example.gpkg) if you want to play along.



{% highlight r %}
library(sf)

# check available layers from a geopackage
st_layers(paste0(here::here(), "/data/gpkg_in_R_example.gpkg"))
{% endhighlight %}



{% highlight text %}
## Driver: GPKG 
## Available layers:
##         layer_name geometry_type features fields
## 1 usgs_gages_clean      3D Point     2239      2
## 2      lighthouses         Point       54      2
## 3       oceantrash         Point     7063     62
## 4            piers         Point      200      4
## 5            ports         Point       97     17
{% endhighlight %}

Next we can actually bring a layer into R, and interact with it. The `sf` package is great because it uses simple dataframes with a spatial list-column tacked at the end. Here we read in a spatial object (e.g., a shapfile), and then make a quick interactive map!


{% highlight r %}
# read in layers, suppress messages with quiet=TRUE
usgs <- st_read(paste0(here::here(), "/data/gpkg_in_R_example.gpkg"), layer='usgs_gages_clean', quiet = FALSE)
{% endhighlight %}



{% highlight text %}
## Reading layer `usgs_gages_clean' from data source `/Users/ryanpeek/Documents/github/WEBSITES/ryanpeek.github.io/data/gpkg_in_R_example.gpkg' using driver `GPKG'
## Simple feature collection with 2239 features and 2 fields
## geometry type:  POINT
## dimension:      XYZ
## bbox:           xmin: -364760.2 ymin: -602451.8 xmax: 538984.1 ymax: 447251.2
## epsg (SRID):    NA
## proj4string:    +proj=aea +lat_1=34 +lat_2=40.5 +lat_0=0 +lon_0=-120 +x_0=0 +y_0=-4000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs
{% endhighlight %}



{% highlight r %}
# check what the data class is:
class(usgs)
{% endhighlight %}



{% highlight text %}
## [1] "sf"         "data.frame"
{% endhighlight %}



{% highlight r %}
# check the CRS/projections:
st_crs(usgs)
{% endhighlight %}



{% highlight text %}
## Coordinate Reference System:
##   No EPSG code
##   proj4string: "+proj=aea +lat_1=34 +lat_2=40.5 +lat_0=0 +lon_0=-120 +x_0=0 +y_0=-4000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
{% endhighlight %}



{% highlight r %}
# view a map of spatial data!
mapview(usgs, col.regions="skyblue", alpha.regions=0.6, layer.name="USGS Gages")
{% endhighlight %}

<img src="/img/Rfig/2019-09-17-reading-databases-in-R.Rmd//readgpkg-1.png" title="plot of chunk readgpkg" alt="plot of chunk readgpkg" width="100%" />

Really simple and clean. 


### `GDB`

The process is pretty much the same for a GDB. I don't have an example GDB to play with here, but the code below would work just the same. For more info, definitely check out the [`sf`](https://r-spatial.github.io/sf/index.html) website.


{% highlight r %}
yourlayer <- st_read(dsn = "my_large_geospatial_DB.gdb", layer = "my_interesting_spatial_layer")
{% endhighlight %}


## Summary

I'll try to update this with more info on writing to a database in the future, but the same packages are used and the process is largely the same. Hope this is helpful! There are probably many other snippets, packages, and options available that I haven't covered here, but hopefully this gets things started. 


<img src="//Users/ryanpeek/Documents/github/WEBSITES/ryanpeek.github.io/img/sierra_newt.jpg" title="Sierra newt in moss" alt="Sierra newt in moss" width="75%" />


