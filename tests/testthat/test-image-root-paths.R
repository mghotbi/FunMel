test_that("Windows canonical paths accept drive, UNC and mixed slash spellings", {
  inside <- FunMel:::canonical_paths_within_root
  expect_true(inside("C:/Users/Mitra/photos/batch/plate.JPG", "C:/Users/Mitra/photos", TRUE))
  expect_true(inside("C:\\Users\\Mitra\\photos\\batch\\plate.JPG", "C:/Users/Mitra/photos/", TRUE))
  expect_true(inside("c:/users/mitra/PHOTOS/plate.JPG", "C:/Users/Mitra/photos", TRUE))
  expect_true(inside("//server/share/photos/batch/plate.JPG", "//server/share/photos/", TRUE))
  expect_true(inside("C:/plate.JPG", "C:/", TRUE))
  expect_false(inside("C:/Users/Mitra/photos_backup/plate.JPG", "C:/Users/Mitra/photos", TRUE))
  expect_false(inside("D:/photos/plate.JPG", "C:/photos", TRUE))
  expect_false(inside("//server/other/photos/plate.JPG", "//server/share/photos", TRUE))
  expect_false(inside("C:/photos", "C:/photos", TRUE))
})

test_that("POSIX canonical paths retain case and component boundaries", {
  inside <- FunMel:::canonical_paths_within_root
  expect_equal(inside(c("/photos/a.jpg", "/photos2/a.jpg", "/Photos/a.jpg"), "/photos", FALSE), c(TRUE,FALSE,FALSE))
  expect_true(inside("/photos/batch/a.jpg", "/photos/", FALSE))
  expect_true(inside("/photos/a.jpg", "/", FALSE))
})

test_that("real image roots and photographs are canonicalized together", {
  root <- withr::local_tempdir(pattern="FunMel paths ")
  images <- file.path(root,"photos"); dir.create(images)
  batch <- file.path(images,"batch 1"); dir.create(batch)
  photo <- file.path(batch,"plate.JPG"); file.create(photo)
  outside <- file.path(root,"photos_backup"); dir.create(outside)
  other <- file.path(outside,"plate.JPG"); file.create(other)
  within <- FunMel:::image_paths_within_root
  expect_equal(within(c(photo,other),images),c(TRUE,FALSE))
  expect_true(within(photo,paste0(images,"/")))
  withr::with_dir(root, expect_true(within(file.path("photos","batch 1","plate.JPG"),"photos")))
  expect_true(within(file.path(batch,"..","batch 1","plate.JPG"),images))
  expect_false(within(file.path(images,"..","photos_backup","plate.JPG"),images))
})

test_that("symlinks outside the image root cannot bypass containment", {
  skip_on_os("windows") # Symlink creation can require administrator privileges.
  root <- withr::local_tempdir(); images <- file.path(root,"photos"); dir.create(images)
  outside <- file.path(root,"outside.JPG"); file.create(outside)
  link <- file.path(images,"linked.JPG")
  if(!file.symlink(outside,link)) skip("Symlinks unavailable")
  expect_false(FunMel:::image_paths_within_root(link,images))
})
