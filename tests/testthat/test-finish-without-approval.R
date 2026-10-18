test_that("saved projects finalize without approving legacy metadata flags", {
  d <- example_experiment(seed=42)$colonies
  original <- d$MI_mean
  template <- unique(d[setdiff(names(d),c("colony_id","MI_mean","detected","is_target"))])
  for(flag in list(FALSE,NA,NULL)) {
    m <- template
    m$metadata_confirmed <- flag
    m$qc_pass <- FALSE
    m[["User annotation"]] <- "keep"
    home <- withr::local_tempdir()
    p <- structure(list(project_dir=home,metadata_file=file.path(home,"plate_metadata.csv"),
      result_file=file.path(home,"image_analysis.rds"),
      reviewed_file=file.path(home,"reviewed_analysis.rds")),class="funmel_project")
    saveRDS(list(colonies=d,plates=m,spots=data.frame(),profiles=data.frame(),failed=data.frame()),p$result_file)
    utils::write.csv(m,p$metadata_file,row.names=FALSE)
    z <- suppressWarnings(finish_experiment(p,method="plate_means"))
    expect_equal(nrow(z$melanization_coefficient),6L)
    expect_equal(z$colonies$MI_mean,original)
    expect_true(all(!z$metadata$qc_pass))
    expect_true(all(z$metadata[["User annotation"]]=="keep"))
    if(is.null(flag)) expect_false("metadata_confirmed" %in% names(z$metadata))
    else if(is.na(flag)) expect_true(all(is.na(z$metadata$metadata_confirmed)))
    else expect_true(all(!z$metadata$metadata_confirmed))
    expect_true(file.exists(p$reviewed_file))
    expect_true(file.exists(file.path(home,"treatment_comparison.pdf")))
    expect_error(finish_experiment(p,require_qc=TRUE),"qc_pass")
  }
})
