# Run from the unpacked FunMel source folder.
(function() {
  root <- normalizePath(".",mustWork=TRUE)
  if(!file.exists(file.path(root,"DESCRIPTION")) ||
     !file.exists(file.path(root,"vignettes","Real-14-day.Rmd")))
    stop("Set the working directory to the unpacked FunMel source folder first.",call.=FALSE)
  for(pkg in c("pkgdown","callr","cli"))
    if(!requireNamespace(pkg,quietly=TRUE)) stop("Install ",pkg," before building the website.",call.=FALSE)
  expected <- read.dcf(file.path(root,"DESCRIPTION"),fields=c("Package","Version"))
  if(expected[1,"Package"]!="FunMel") stop("This is not the FunMel source folder.",call.=FALSE)

  # Undo only the exact console override applied by earlier build scripts.
  if(identical(getOption("cli.num_colors"),1) &&
     identical(getOption("crayon.enabled"),FALSE) && identical(Sys.getenv("NO_COLOR"),"1")) {
    options(cli.num_colors=NULL,crayon.enabled=NULL)
    Sys.unsetenv("NO_COLOR")
  }
  colours <- cli::num_ansi_colors()
  graphics.off()
  theme <- file.path(root,"vignettes","funmel-theme.css")
  if(!file.exists(theme)) stop("The vignette theme is missing from the source folder.",call.=FALSE)
  dir.create(file.path(root,"pkgdown"),showWarnings=FALSE)
  if(!file.copy(theme,file.path(root,"pkgdown","extra.css"),overwrite=TRUE))
    stop("Could not update the website theme.",call.=FALSE)
  source(file.path(root,"inst","scripts","refresh_favicons.R"),local=TRUE)
  refresh_funmel_favicons(root)

  # Website articles are rendered below from root/vignettes. Install a clean
  # runtime copy without vignette sources/indices: raw GitHub checkouts do not
  # contain inst/doc, which some R versions require when indexing vignettes.
  stage <- tempfile("FunMel_site_source_")
  dir.create(stage)
  on.exit(unlink(stage,recursive=TRUE),add=TRUE)
  stage_root <- file.path(stage,"FunMel")
  dir.create(stage_root)
  entries <- list.files(root,all.files=TRUE,no..=TRUE,full.names=TRUE)
  entries <- entries[!basename(entries) %in% c(".git",".Rproj.user","docs",
    "vignettes","build","release_validation","tc")]
  if(!all(file.copy(entries,stage_root,recursive=TRUE,copy.date=TRUE)))
    stop("Could not prepare the temporary website installation.",call.=FALSE)
  unlink(file.path(stage_root,"inst","doc"),recursive=TRUE)

  build_lib <- tempfile("FunMel_site_library_")
  dir.create(build_lib)
  on.exit(unlink(build_lib,recursive=TRUE),add=TRUE)
  install_log <- tempfile("FunMel_install_",fileext=".log")
  on.exit(unlink(install_log),add=TRUE)
  cli::cli_alert_info("Installing local FunMel {expected[1,'Version']} for the website build.")
  status <- system2(file.path(R.home("bin"),"R"),
    c("CMD","INSTALL","--preclean",paste0("--library=",shQuote(build_lib)),shQuote(stage_root)),
    stdout=install_log,stderr=install_log)
  if(!identical(as.integer(status),0L)) {
    cat(paste(readLines(install_log,warn=FALSE),collapse="\n"),"\n")
    stop("Local installation failed. The website was not built with another installed version.",call.=FALSE)
  }

  callr::r(function(root,build_lib,expected,colours) {
    .libPaths(c(build_lib,.libPaths()))
    ns <- loadNamespace("FunMel",lib.loc=build_lib)
    loaded <- normalizePath(getNamespaceInfo(ns,"path"),mustWork=TRUE)
    wanted <- normalizePath(file.path(build_lib,"FunMel"),mustWork=TRUE)
    if(!identical(loaded,wanted) || as.character(getNamespaceVersion(ns))!=expected)
      stop("Website build did not load the requested local FunMel installation.",call.=FALSE)

    # Exercise the actual finalizer with FALSE flags; never approve rows implicitly.
    d <- FunMel::example_experiment(seed=42)$colonies
    m <- unique(d[setdiff(names(d),c("colony_id","MI_mean","detected","is_target"))])
    m$metadata_confirmed <- FALSE
    m$qc_pass <- FALSE
    r <- list(colonies=d,plates=m,profiles=data.frame(),spots=data.frame(),failed=data.frame())
    z <- suppressMessages(suppressWarnings(FunMel::finalize_analysis(r,m)))
    if(!nrow(z$melanization_coefficient) || any(z$metadata$metadata_confirmed))
      stop("The installed finalization contract failed before website rendering.",call.=FALSE)
    options(cli.num_colors=colours,crayon.colors=colours,crayon.enabled=colours>1,cli.hyperlink=FALSE)
    graphics.off()
    cli::cli_alert_success("Verified FunMel {expected} from the dedicated build library.")
    pkgdown::build_site(pkg=root,install=FALSE,new_process=FALSE,devel=FALSE,lazy=FALSE,preview=FALSE)
    invisible(NULL)
  },args=list(root=root,build_lib=build_lib,expected=expected[1,"Version"],colours=colours),
    libpath=c(build_lib,.libPaths()),system_profile=FALSE,user_profile=FALSE,show=TRUE)
})()
