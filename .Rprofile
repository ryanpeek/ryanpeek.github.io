#library(leaflet)
set.seed(0102)
knitr::opts_chunk$set(out.width = '100%')

options(help_type="html")
options(prompt=">")
options(continue="   +")


if(Sys.info()[7]=="rapeek") {
  root<-"C://Users//rapeek.AD3//Dropbox//R//"
} else if (Sys.info()[7]=="ryanpeek") {
  root<-"//Users//ryanpeek//Dropbox/R/"
}


.First <- function(){
  cat("\nYarRRR!\n-------------------\n githubsite \n",sep="")
  cat("-------------------\n\n",sep="")
  
  if(file.exists(paste(root,"//functions//RWatershedFunctions.r",sep=""))){
    source(paste(root,"//functions//RWatershedFunctions.r",sep=""))
    cat("RWatershedFunctions.r was loaded, to view list of current functions type:\n",sep="")
    cat("print.functions()\n\n",sep="")
  } else {
    print(cat("no RWatershedFunctions file found, check dir\n",sep=""))
  }
}

cat("\014")
cat(R.version$version.string,"\n",sep="")
cat("\nSuccessfully loaded .Rprofile at", date(), "\n")
