knitAll = function(overwrite = FALSE, ..., sitePath = './') {
    # if overwrite, will rebuild all files in _Rmd/ to .md in _posts/blog/;
    # if not, will only write files that haven't already been built (ie,
    # aren't already in _posts/blog/)
    # ... goes to opts_chunk$set

    rmdFiles = list.files(file.path(sitePath, '_Rmd'), pattern = '\\.Rmd')
    rmdFiles = substr(rmdFiles, 1, nchar(rmdFiles) - 4)
    if(!overwrite) {
        mdFiles =  list.files(file.path(sitePath, '_posts/blog'), pattern = '\\.md')
        rmdFiles = rmdFiles[!sapply(rmdFiles, function(f) any(grep(f, mdFiles)))]
    }
    invisible(lapply(rmdFiles, knitPost, ...))

}

knitPost <- function(file, cache = TRUE, ..., highlight = "pygments", sitePath = './') {

    # File would be "my-post-title", to build sitePath/_Rmd/my-post-title.Rmd
    # which would put 2016-04-27-my-post-title.md in sitePath/_posts/blog/
    # ... goes to knitr::opts_chunk$set (e.g. message = FALSE)

    require('knitr')
    oldwd = getwd()
    setwd(sitePath)

    ## Blog-specific directories.  This will depend on how you organize your blog.
    rmdPath <- paste0(sitePath, "_Rmd") # directory where your Rmd-files reside (relative to base)
    mdPath <- paste0(sitePath, "_posts/") # directory for converted markdown files
    figDir <- file.path("img/Rfig", file, '/') # directory to save figures
    cachePath <- paste0(sitePath, "_cache/", file, '/') # necessary for plots

    # Make sure the .Rmd file is found
    if(!grepl('\\.Rmd', file))
        file = paste0(file, '.Rmd')
    if(!file %in% list.files(rmdPath))
        stop(paste(file, "not found in", rmdPath))

    render_jekyll(highlight)
    opts_knit$set(base.url = '/', baseDir = sitePath)
    opts_chunk$set(fig.path = figDir, cache.path = cachePath,
                   fig.width = 8.5, fig.height = 4, dev = 'svg',
                   cache = cache, warning = FALSE, message = FALSE, ...)

    mdFile = paste0(format(Sys.time(), '%Y-%m-%d'), '-', gsub('\\.Rmd', '\\.md', file))

    # If there is a corresponding .md file with a different date, make that the target
    # Otherwise get multiple versions of the post on different dates
    oldPost = grep(substr(mdFile, 12, nchar(mdFile)), list.files(mdPath), value = TRUE)
    if(length(oldPost))
        mdFile = oldPost

    # If the corresponding .md file is there, ask the user whether to overwrite
    if(mdFile %in% list.files(mdPath)) {
        ow = readline(prompt = paste(mdFile, 'exists. Overwrite? (y/n): '))
        if(!ow %in% c('y', 'yes', 'Y'))
            return(message('Did not overwrite ', mdFile))
    }

    fileWritten =
        knit(input = file.path(rmdPath, file),
             output = file.path(mdPath, mdFile),
             envir = parent.frame(),
             quiet = TRUE)

    message(paste('File written:', fileWritten))
    setwd(oldwd)

}
