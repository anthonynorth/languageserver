context("Test Symbol")

test_that("Document Symbol works", {
    skip_on_cran()
    client <- language_client()

    defn_file <- withr::local_tempfile(fileext = ".R")
    writeLines(c(
        "f <- function(x) {",
        "  x + 1",
        "}",
        "g <- function(x) { x - 1 }",
        "p <- 1",
        "m <- list(",
        "  x = p + 1",
        ")"
    ), defn_file)

    client %>% did_save(defn_file)
    result <- client %>% respond_document_symbol(defn_file)

    expect_equal(result %>% map_chr(~ .$name) %>% sort(), c("f", "g", "p", "m") %>% sort())
    expect_equivalent(
        result %>% detect(~ .$name == "f") %>% pluck("location", "range"),
        range(position(0, 0), position(2, 1))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "g") %>% pluck("location", "range"),
        range(position(3, 0), position(3, 26))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "p") %>% pluck("location", "range"),
        range(position(4, 0), position(4, 6))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "m") %>% pluck("location", "range"),
        range(position(5, 0), position(7, 1))
    )
})

test_that("Document section symbol works", {
    skip_on_cran()
    client <- language_client(capabilities = list(
        textDocument = list(
            documentSymbol = list(
                hierarchicalDocumentSymbolSupport = TRUE
            )
        )
    ))

    defn_file <- withr::local_tempfile(fileext = ".R")
    writeLines(c(
        "# section1 ####",
        "f <- function(x) {",
        "  ## step1 ====",
        "  x + 1",
        "  ## step2 ====",
        "  x + 2",
        "}",
        "# section2 ####",
        "g <- function(x) { x - 1 }",
        "p <- 1",
        "m <- list(",
        "  x = p + 1",
        ")"
    ), defn_file)

    client %>% did_save(defn_file)
    result <- client %>% respond_document_symbol(defn_file)

    expect_equal(
        result %>% map_chr(~ .$name) %>% sort(),
        c("section1", "f", "step1", "step2", "section2", "g", "p", "m") %>% sort()
    )
    expect_equivalent(
        result %>% detect(~ .$name == "section1") %>% pluck("location", "range"),
        range(position(0, 0), position(6, 1))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "f") %>% pluck("location", "range"),
        range(position(1, 0), position(6, 1))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "step1") %>% pluck("location", "range"),
        range(position(2, 0), position(2, 15))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "step2") %>% pluck("location", "range"),
        range(position(4, 0), position(4, 15))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "section2") %>% pluck("location", "range"),
        range(position(7, 0), position(12, 1))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "g") %>% pluck("location", "range"),
        range(position(8, 0), position(8, 26))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "p") %>% pluck("location", "range"),
        range(position(9, 0), position(9, 6))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "m") %>% pluck("location", "range"),
        range(position(10, 0), position(12, 1))
    )
})

test_that("Workspace Symbol works", {
    skip_on_cran()
    client <- language_client()

    defn_file <- withr::local_tempfile(fileext = ".R")
    defn2_file <- withr::local_tempfile(fileext = ".R")
    writeLines(c(
        "f1 <- function(x) {",
        "  x + 1",
        "}",
        "g <- function(x) { x - 1 }",
        "p1 <- 1",
        "m1 <- list(",
        "  x = p + 1",
        ")"
    ), defn_file)
    writeLines(c(
        "f2 <- function(x) {",
        "  x + 1",
        "}",
        "p2 <- 1",
        "m2 <- list(",
        "  x = p + 1",
        ")"
    ), defn2_file)

    client %>% did_save(defn_file)
    client %>% did_save(defn2_file)

    expected_names <- c("f1", "f2") %>% sort()
    result <- client %>% respond_workspace_symbol(
        query = "f",
        retry_when = function(result) length(result) < 2
    )

    result_names <- result %>%
        map_chr(~ .$name) %>%
        sort()
    expect_equal(result_names, expected_names)

    expected_names <- c("p1", "p2") %>% sort()
    result <- client %>% respond_workspace_symbol(
        query = "p",
        retry_when = function(result) length(result) < 2
    )

    result_names <- result %>%
        map_chr(~ .$name) %>%
        sort()
    expect_equal(result_names, expected_names)
})

test_that("Document section symbol works in Rmarkdown", {
    skip_on_cran()
    client <- language_client(capabilities = list(
        textDocument = list(
            documentSymbol = list(
                hierarchicalDocumentSymbolSupport = TRUE
            )
        )
    ))

    defn_file <- withr::local_tempfile(fileext = ".Rmd")
    writeLines(c(
        "---",
        "title: r markdown",
        "# author: me",
        "---",
        "## section1",
        "Some text here",
        "### subsection1",
        "```{r}",
        "f <- function(x) {",
        "  x + 1",
        "}",
        "```",
        "## section2",
        "```{r}",
        "g <- function(x) { x - 1 }",
        "```",
        "```{r,eval=FALSE}",
        "test",
        "```",
        "```{r chunk1}",
        "p <- 1",
        "```",
        "```{r chunk1a, eval=FALSE}",
        "test",
        "```",
        "```{r 'chunk2'}",
        "test",
        "```",
        "```{r 'chunk2a', eval=TRUE}",
        "test",
        "```",
        "```{r \"chunk3\"}",
        "test",
        "```",
        "```{r \"chunk3a\", eval=FALSE}",
        "test",
        "```",
        "```{r \"chunk4, new\", eval=FALSE}",
        "test",
        "```",
        "```{r eval=FALSE}",
        "test",
        "```"
    ), defn_file)

    client %>% did_save(defn_file)
    result <- client %>% respond_document_symbol(defn_file)

    expect_equal(
        result %>% map_chr(~ .$name) %>% sort(),
        c("section1", "subsection1", "unnamed-chunk-1",
            "f", "section2", "unnamed-chunk-2", "g",
            "unnamed-chunk-3", "chunk1", "p", "chunk1a", "chunk2", "chunk2a",
            "chunk3", "chunk3a", "chunk4, new", "unnamed-chunk-4"
        ) %>% sort()
    )
    expect_equivalent(
        result %>% detect(~ .$name == "section1") %>% pluck("location", "range"),
        range(position(4, 0), position(11, 3))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "subsection1") %>% pluck("location", "range"),
        range(position(6, 0), position(11, 3))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "f") %>% pluck("location", "range"),
        range(position(8, 0), position(10, 1))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "section2") %>% pluck("location", "range"),
        range(position(12, 0), position(42, 3))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "g") %>% pluck("location", "range"),
        range(position(14, 0), position(14, 26))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "unnamed-chunk-1") %>% pluck("location", "range"),
        range(position(7, 0), position(11, 3))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "unnamed-chunk-2") %>% pluck("location", "range"),
        range(position(13, 0), position(15, 3))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "unnamed-chunk-3") %>% pluck("location", "range"),
        range(position(16, 0), position(18, 3))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "chunk1") %>% pluck("location", "range"),
        range(position(19, 0), position(21, 3))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "p") %>% pluck("location", "range"),
        range(position(20, 0), position(20, 6))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "chunk1a") %>% pluck("location", "range"),
        range(position(22, 0), position(24, 3))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "chunk2") %>% pluck("location", "range"),
        range(position(25, 0), position(27, 3))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "chunk2a") %>% pluck("location", "range"),
        range(position(28, 0), position(30, 3))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "chunk3") %>% pluck("location", "range"),
        range(position(31, 0), position(33, 3))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "chunk3a") %>% pluck("location", "range"),
        range(position(34, 0), position(36, 3))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "chunk4, new") %>% pluck("location", "range"),
        range(position(37, 0), position(39, 3))
    )
    expect_equivalent(
        result %>% detect(~ .$name == "unnamed-chunk-4") %>% pluck("location", "range"),
        range(position(40, 0), position(42, 3))
    )
})
