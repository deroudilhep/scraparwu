# Librairies -------------------------------------------------------------------

library(tidyverse)
library(RSelenium)
library(rvest)

# Régler les variables utiles du programme -------------------------------------

url <- "https://www.shanghairanking.com/rankings/arwu"
#years <- seq(2003, year(today()), 1)
years <- seq(2003, 2022, 1)

# Régler les variables pour la navigation --------------------------------------

nav <- "chrome"
naver <- "114"

# Vérification des drivers -----------------------------------------------------

selenium_object <- wdman::selenium(retcommand = TRUE, check = FALSE)
print(selenium_object)

# Choisir la dernière version du driver chrome adéquate ET disponible ----------

if (nav == "chrome") {
  chromever <- binman::list_versions("chromedriver") %>%
  unlist() %>%
  .[str_detect(., paste0("^", naver))] %>%
  max()
} else {
  chromever <- NULL
}

# Initialiser le remote driver -------------------------------------------------

rmdr <- rsDriver(
  browser = nav,
  chromever = chromever,
  verbose = FALSE,
  port = netstat::free_port()
)
cli <- rmdr$client

# Scrape -----------------------------------------------------------------------

get_html <- function(cli) {
  html <- cli$getPageSource() %>%
    unlist() %>%
    read_html()
}

arwu <- list()

print("scrape")
for (i in seq_along(years)) {
  print(paste0("├─ ", years[i]))
  cli$navigate(paste(url, years[i], sep = "/"))
  pagesn <- get_html(cli) %>%
    html_element(xpath = "//ul[@class='ant-pagination']/li[last()-1]/a") %>%
    html_text() %>%
    as.numeric()
  pageb <- cli$findElement("class name","ant-pagination-next")
  optn <- get_html(cli) %>%
    html_elements(
      xpath = "//table[@class='rk-table']/thead/tr/th[last()]/*/*/*/*/li"
    ) %>%
    html_text()
  optp <- cli$findElement(
    "xpath",
    "//table[@class='rk-table']/thead/tr/th[last()]"
  )
  opt <- cli$findElements(
    "xpath",
    "//table[@class='rk-table']/thead/tr/th[last()]/*/*/*/*/li"
  )
  pages <- list()
  for (j in seq_along(seq(1, pagesn, 1))) {
    print(paste0("│  ├─ page ", j))
    if (j > 1) {
      optp$clickElement()
      opt[[1]]$clickElement()
    }
    table <- get_html(cli) %>%
      html_element(xpath = "//table[@class='rk-table']") %>%
      html_table()
    flags <- get_html(cli) %>% 
      html_elements(".region-img") %>% 
      html_attr("style")
    table$flags <- flags
    for (k in 2:length(optn)) {
      optp$clickElement()
      opt[[k]]$clickElement()
      val <- get_html(cli) %>%
        html_elements(
          xpath = "//table[@class='rk-table']/tbody/tr/td[last()]"
        ) %>%
        html_text() %>%
        as.numeric()
      table[optn[k]] <- val
    }
    pages[[paste("page", j)]] <- table
    if (j < pagesn) {
      pageb$clickElement()
      cli$executeScript("window.scrollTo(0,0)")
    }
  }
  arwu[[as.character(years[i])]] <- pages
}
print("done!")

# Stopper le serveur -----------------------------------------------------------

rmdr$server$stop()

# Nettoyer les jeux de données et les fusionner --------------------------------

lookup <- c(
  "rang_mond" = "World\nRank",
  "etab" = "Institution",
  "rang_reg" = "National/Regional\nRank",
  "score_tot" = "Total Score",
  "pays_code" = "flags",
  "award" = "AwardHiCiN&SPUBPCP",
  "alumni" = "AlumniAwardHiCiN&SPUBPCP",
  "award" = "Award",
  "hici" = "HiCi",
  "n&s" = "N&S",
  "pub" = "PUB",
  "pcp" = "PCP"
)
col <- c(
  "annee",     "rang_mond", "etab",
  "pays_code", "pays_nom",  "rang_reg",
  "score_tot", "alumni",    "award",
  "hici",      "n&s",       "pub",
  "pcp"
)
table_pays <- read_delim("table_code_pays.csv", delim = ";")

arwu_clean <- arwu %>%
  map(function(x) map(x, rename, any_of(lookup))) %>%
  map(
    function(x) map(
      x,
      mutate,
      rang_reg = as.character(rang_reg),
      rang_mond = as.character(rang_mond)
    )
  ) %>%
  map(bind_rows) %>%
  map2(years, function(x, y) mutate(x, annee = y)) %>%
  map(mutate, etab = str_remove_all(etab, "\\n.+")) %>%
  map(mutate, pays_code = str_sub(pays_code, -9L, -8L)) %>%
  map(left_join, table_pays) %>%
  map(select, any_of(col))

# Exporter à différents formats ------------------------------------------------

writexl::write_xlsx(arwu_clean, "arwu.xlsx")
