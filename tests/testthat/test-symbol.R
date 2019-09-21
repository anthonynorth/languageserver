context("Test Symbol")

test_that("Document Symbol works", {
    skip_on_cran()
    client <- language_client()

    withr::local_tempfile(c("defn_file"), fileext = ".R")
    writeLines(c("f <- function(x) {", "  x + 1", "}",
                 "g <- function(x) { x - 1 }"), defn_file)

    client %>% did_save(defn_file)
    result <- client %>% respond(
        "textDocument/documentSymbol",
        list(textDocument = list(uri = path_to_uri(defn_file))))

    expect_equal(result %>% map_chr(~ .$name) %>% sort(), c("f", "g"))
    expect_equivalent(
        result %>% detect(~ .$name == "f") %>%
            extract2("location") %>% extract2("range"),
        range(position(0, 0), position(2, 0))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "g") %>%
            extract2("location") %>% extract2("range"),
        range(position(3, 0), position(3, 25))
    )

})

test_that("Workspace Symbol works", {
    skip_on_cran()
    client <- language_client()

    withr::local_tempfile(c("defn_file", "defn2_file"), fileext = ".R")
    writeLines(c("f1 <- function(x) {", "  x + 1", "}",
                 "g <- function(x) { x - 1 }"), defn_file)
    writeLines(c("f2 <- function(x) {", "  x + 1", "}"), defn2_file)

    client %>% did_save(defn_file)
    client %>% did_save(defn2_file)

    expected_names <- c("f1", "f2")
    result <- client %>% respond(
        "workspace/symbol", list(query = "f"),
        retry_when = function(result) length(result) < 2)

    result_names <- result %>% map_chr(~ .$name) %>% sort()
    expect_equal(result_names, expected_names)
})