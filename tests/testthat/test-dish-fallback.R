test_that("dish fitting retries a valid alternative after a structured error", {
  detect <- FunMel::detect_plate
  shim <- new.env(parent = environment(detect))
  environment(detect) <- shim
  attempts <- character()
  shim$fit_dish_circle <- function(L, background, seed) {
    attempts <<- c(attempts, background)
    if (background != "dark") {
      stop(structure(
        list(message = "Too few dish-edge pixels", rlang = list()),
        class = c("test_dish_error", "error", "condition")
      ))
    }
    list(x = 100, y = 100, r = 80, coverage = 0.9, rmse = 1)
  }
  plate <- read_plate(array(0, c(200, 200, 3)))
  out <- detect(plate)
  expect_identical(attempts, c("auto", "dark", "light"))
  expect_identical(out$dish$method, "auto_fallback_dark")
  expect_equal(out$dish$r_outer, 80)
})

test_that("a photograph without a fit reports the original dish failure", {
  plate <- read_plate(array(0, c(200, 200, 3)))
  expect_error(detect_plate(plate), "Too few dish-edge pixels",
               class = "funmel_dish_detection_error")
})
