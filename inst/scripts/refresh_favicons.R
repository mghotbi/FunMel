# Local website assets: no external favicon service or network request.
refresh_funmel_favicons <- function(root=".") {
  logo <- file.path(root,"man","figures","logo.png")
  if(!file.exists(logo)) stop("Run this from the FunMel source folder containing man/figures/logo.png.",call.=FALSE)
  if(!requireNamespace("magick",quietly=TRUE) || !requireNamespace("jsonlite",quietly=TRUE))
    stop("Install magick and jsonlite before building website assets.",call.=FALSE)
  target <- file.path(root,"pkgdown","favicon")
  dir.create(target,recursive=TRUE,showWarnings=FALSE)
  image <- magick::image_read(logo)
  square <- function(size) magick::image_extent(
    magick::image_resize(image,paste0(size,"x",size)),
    paste0(size,"x",size),gravity="center",color="none")
  sizes <- c("favicon-16x16.png"=16,"favicon-32x32.png"=32,"favicon-96x96.png"=96,
    "apple-touch-icon-60x60.png"=60,"apple-touch-icon-76x76.png"=76,
    "apple-touch-icon-120x120.png"=120,"apple-touch-icon.png"=180,
    "web-app-manifest-192x192.png"=192,"web-app-manifest-512x512.png"=512)
  for(name in names(sizes)) magick::image_write(square(sizes[[name]]),file.path(target,name),format="png")
  magick::image_write(magick::image_join(lapply(c(16,32,48),square)),file.path(target,"favicon.ico"),format="ico")
  encoded <- jsonlite::base64_enc(magick::image_write(square(512),format="png"))
  writeLines(paste0('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 512 512"><image width="512" height="512" xlink:href="data:image/png;base64,',
    gsub("[\r\n]","",encoded),'"/></svg>'),file.path(target,"favicon.svg"))
  jsonlite::write_json(list(name="FunMel",short_name="FunMel",
    icons=list(list(src="web-app-manifest-192x192.png",sizes="192x192",type="image/png"),
               list(src="web-app-manifest-512x512.png",sizes="512x512",type="image/png")),
    theme_color="#745523",background_color="#FFFCF7",display="standalone"),
    file.path(target,"site.webmanifest"),auto_unbox=TRUE,pretty=TRUE)
  # Freshly generated assets may need timestamp ordering after a file copy.
  stamp <- max(Sys.time(),file.info(logo)$mtime)
  Sys.setFileTime(list.files(target,full.names=TRUE),stamp)
  invisible(target)
}
