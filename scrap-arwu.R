# Author : Pierre Deroudilhe
# License : MIT
# See https://github.com/deroudilhep/scrap-arwu for documentation

java_condition <- FALSE
warning("This script needs Java to execute properly.")
while(java_condition == FALSE) {
  if (interactive()) {
    java <- readline("Do you have Java installed? Y/N :  ")
    if (java == "Y" | java == "y") {
      message("Ok let's go!")
      java_condition <- TRUE
    } else {
      if (java == "N" | java == "n") {
        stop("Please come back after you've installed Java.")
      } else {
        message("Invalid answer, let's do that again.")
      }
    }
  } else {
    cat("Do you have Java installed? Y/N : ");
    java <- readLines("stdin", n=1);
    if (java == "Y" | java == "y") {
      message("Ok let's go!")
      java_condition <- TRUE
      Sys.sleep(3)
    } else {
      if (java == "N" | java == "n") {
        stop("Please come back after you've installed Java.")
      } else {
        message("Invalid answer, let's do that again.")
        Sys.sleep(3)
      }
    }
  } 
}

message("Loading libraries, please wait...")

# install.packages("tidyverse")
suppressMessages(library(tidyverse)) # manipulation statistique 
# install.packages("RSelenium")
suppressMessages(library(RSelenium)) # activer le serveur Selenium qui nous permet de naviguer sur internet 
# install.packages("rvest")
suppressMessages(library(rvest)) # scraper 
# install.packages("netstat")
suppressMessages(library(netstat)) # trouver un port inutilisé pour le serveur Selenium (si besoin)
# install.packages("lubridate")
suppressMessages(library(lubridate)) # pour manipuler plus facilement l'année

current_year <- year(today())

year_selection <- FALSE
while(year_selection == FALSE) {
  if (interactive()) {
    year <- readline("Which ARWU year do you want to get? ")
    if (year <= current_year & year >= 2003 & grepl("^\\d\\d\\d\\d$", year)) {
      message("Ok let's go!")
      year_selection <- TRUE
      Sys.sleep(3)
    } else {
      message("Invalid year format or no ARWU exists for the year you gave. Let's do that again.")
      Sys.sleep(3)
    }
  } else {
    cat("Which ARWU year do you want to get? ");
    year <- readLines("stdin", n=1);
    if (year <= current_year & year >= 2003 & grepl("^\\d\\d\\d\\d$", year)) {
      message("Ok let's go!")
      year_selection <- TRUE
      Sys.sleep(3)
    } else {
      message("Invalid year format or no ARWU exists for the year you gave. Let's do that again.")
      Sys.sleep(3)
    }
  }
}

driver_version_selection <- FALSE
while(driver_version_selection == FALSE) {
  if (interactive()) {
    message("What are the first three digits of your Chrome version? \nIf you do not know where to find that information, \nplease see documentation at https://github/deroudilhep/scrap-arwu")
    three_digits <- readline("First three digits? ")
    if (grepl("^\\d\\d\\d$", three_digits)) {
      message("Ok let's go!")
      chromedriver_versions <- unlist(binman::list_versions("chromedriver"))
      matching_versions_indices <- agrep(paste("^", three_digits, sep = ""), chromedriver_versions)
      chosen_version_index <- as.numeric(matching_versions_indices[[1]])
      chosen_version <- as.character(chromedriver_versions[[chosen_version_index]])
      driver_version_selection <- TRUE
      Sys.sleep(3)
    } else {
      message("Invalid input, let's do that again")
      Sys.sleep(3)
    }
  } else {
    message("What are the first three digits of your Chrome version? \nIf you do not know where to find that information, \nplease see documentation at https://github/deroudilhep/scrap-arwu")
    cat("First three digits? ");
    three_digits <- readLines("stdin", n=1);
    if (grepl("^\\d\\d\\d$", three_digits)) {
      message("Ok let's go!")
      chromedriver_versions <- unlist(binman::list_versions("chromedriver"))
      matching_versions_indices <- agrep(paste("^", three_digits, sep = ""), chromedriver_versions)
      chosen_version_index <- as.numeric(matching_versions_indices[[1]])
      chosen_version <- as.character(chromedriver_versions[[chosen_version_index]])
      driver_version_selection <- TRUE
      Sys.sleep(3)
    } else {
      message("Invalid input, let's do that again")
      Sys.sleep(3)
    }
  }
}

message("Opening browser, please do not touch anything.")

rD <- rsDriver(browser = "chrome",
               chromever = chosen_version,
               verbose = FALSE)
# rD[["server"]]$stop()
remDr <- rD$client
remDr$open(silent = TRUE)

message("Data retrieving in progress. Please wait...")

remDr$navigate(paste("https://www.shanghairanking.com/rankings/arwu/", year, sep = ""))

next_page <- remDr$findElement(using = "class name", 
                               "ant-pagination-next")
# next_page$clickElement()
criterias_list <- remDr$findElement(using = "xpath", 
                                "//table[@class='rk-table']/thead/tr/th[last()]/div/div[1]/div[@class='inputWrapper']")
criterias_list$clickElement()
criterias <- remDr$findElements(using = "xpath", 
                                "//table[@class='rk-table']/thead/tr/th[last()]/div/div[1]/div[@class='rk-tooltip']/ul/li")
criterias[[1]]$clickElement()

page_source <- remDr$getPageSource()
html_page <- read_html(page_source %>% 
                         unlist())

data <- html_page %>% 
  html_element(".rk-table") %>% 
  html_table()
flag_url <- html_page %>% 
  html_elements(".region-img") %>% 
  html_attr("style")
data$country <- flag_url

nb_criterias <- as.numeric(length(criterias))
criteria_count <- 2 

while (criteria_count <= nb_criterias) {
  if (criteria_count == 2) {
    criterias_list$clickElement()
    criterias[[criteria_count]]$clickElement()
  }
  
  page_source <- remDr$getPageSource()
  html_page <- read_html(page_source %>% 
                           unlist())
  
  following_criteria <- html_page %>% 
    html_elements(xpath = "//table[@class='rk-table']/tbody/tr/td[last()]") %>% 
    html_text2()
  data$tmp <- following_criteria
  
  criterias_list$clickElement()
  page_source <- remDr$getPageSource()
  html_page <- read_html(page_source %>% 
                           unlist())
  following_criteria_name <- html_page %>% 
    html_elements(xpath = "//table[@class='rk-table']/thead/tr/th[last()]/div/div[1]/div[@class='rk-tooltip']/ul/li[@class='select-active']") %>% 
    html_text2() %>% tolower()
  data <- data %>% 
    rename(!!following_criteria_name := tmp)
  
  criteria_count <- criteria_count + 1
  if (criteria_count <= nb_criterias) {
    criterias[[criteria_count]]$clickElement()
  }
}

data <- data %>% 
  rename(rang_mondial = 1, 
         etablissement = 2, 
         trash = 3, 
         rang_national = 4, 
         score_total = 5, 
         alumni = 6, 
         pays = 7)
data <- data %>% 
  mutate(rang_mondial = as.character(rang_mondial), 
         rang_national = as.character(rang_national),
         score_total = as.numeric(score_total),
         alumni = as.numeric(alumni),
         award = as.numeric(award),
         hici = as.numeric(hici),
         `n&s` = as.numeric(`n&s`),
         pub = as.numeric(pub),
         pcp = as.numeric(pcp))

last_page <- as.numeric(html_page %>%
                          html_element(xpath ="//ul[@class='ant-pagination']/li[last()-1]") %>%
                          html_text2())
active_page <- 2

while (active_page <= last_page) {
  next_page$clickElement()
  remDr$executeScript("window.scrollTo(0,0)")
  
  criterias_list$clickElement()
  criterias[[1]]$clickElement()
  
  page_source <- remDr$getPageSource()
  html_page <- read_html(page_source %>% 
                           unlist())
  
  data_tmp <- html_page %>% 
    html_element(".rk-table") %>% 
    html_table()
  flag_url <- html_page %>% 
    html_elements(".region-img") %>% 
    html_attr("style")
  data_tmp$country <- flag_url
  
  criteria_count <- 2 
  
  while (criteria_count <= nb_criterias) {
    if (criteria_count == 2) {
      criterias_list$clickElement()
      criterias[[criteria_count]]$clickElement()
    }
    
    page_source <- remDr$getPageSource()
    html_page <- read_html(page_source %>% 
                             unlist())
    
    following_criteria <- html_page %>% 
      html_elements(xpath = "//table[@class='rk-table']/tbody/tr/td[last()]") %>% 
      html_text2()
    data_tmp$tmp <- following_criteria
    
    criterias_list$clickElement()
    page_source <- remDr$getPageSource()
    html_page <- read_html(page_source %>% 
                             unlist())
    following_criteria_name <- html_page %>% 
      html_elements(xpath = "//table[@class='rk-table']/thead/tr/th[last()]/div/div[1]/div[@class='rk-tooltip']/ul/li[@class='select-active']") %>% 
      html_text2() %>% tolower()
    data_tmp <- data_tmp %>% 
      rename(!!following_criteria_name := tmp)
    
    criteria_count <- criteria_count + 1
    if (criteria_count <= nb_criterias) {
      criterias[[criteria_count]]$clickElement()
    }
  }
  
  data_tmp <- data_tmp %>% 
    rename(rang_mondial = 1, 
           etablissement = 2, 
           trash = 3, 
           rang_national = 4, 
           score_total = 5, 
           alumni = 6, 
           pays = 7)
  data_tmp <- data_tmp %>% 
    mutate(rang_mondial = as.character(rang_mondial), 
           rang_national = as.character(rang_national),
           score_total = as.numeric(score_total),
           alumni = as.numeric(alumni),
           award = as.numeric(award),
           hici = as.numeric(hici),
           `n&s` = as.numeric(`n&s`),
           pub = as.numeric(pub),
           pcp = as.numeric(pcp))
  
  data <- data %>% 
    bind_rows(data_tmp)
  
  active_page <- active_page + 1
}

data_clean <- data %>% 
  mutate(trash = pays) %>%
  select(-pays) %>%
  rename(pays = trash) %>%
  separate(etablissement, c("etablissement", 
                            "etablissement_double"), 
           "\n") %>%
  select(-etablissement_double) %>%
  mutate(etablissement = str_trim(etablissement, 
                                  side = "right")) %>%
  mutate(pays = str_extract(pays, 
                            "..\\.png")) %>%
  mutate(pays = gsub("\\.png", 
                     "", 
                     pays)) %>%
  # transposer tous les codes pays en leur nom en français 
  mutate(pays = gsub("^af$", "Afghanistan", pays)) %>%
  mutate(pays = gsub("^za$", "Afrique du Sud", pays)) %>%
  mutate(pays = gsub("^ax$", "Îles Åland", pays)) %>%
  mutate(pays = gsub("^al$", "Albanie", pays)) %>%
  mutate(pays = gsub("^dz$", "Algérie", pays)) %>%
  mutate(pays = gsub("^de$", "Allemagne", pays)) %>%
  mutate(pays = gsub("^ad$", "Andorre", pays)) %>%
  mutate(pays = gsub("^ao$", "Angola", pays)) %>%
  mutate(pays = gsub("^ai$", "Anguilla", pays)) %>%
  mutate(pays = gsub("^aq$", "Antarctique", pays)) %>%
  mutate(pays = gsub("^ag$", "Antigua-et-Barbuda", pays)) %>%
  mutate(pays = gsub("^sa$", "Arabie saoudite", pays)) %>%
  mutate(pays = gsub("^ar$", "Argentine", pays)) %>%
  mutate(pays = gsub("^am$", "Arménie", pays)) %>%
  mutate(pays = gsub("^aw$", "Aruba", pays)) %>%
  mutate(pays = gsub("^au$", "Australie", pays)) %>%
  mutate(pays = gsub("^at$", "Autriche", pays)) %>%
  mutate(pays = gsub("^az$", "Azerbaïdjan", pays)) %>%
  mutate(pays = gsub("^bs$", "Bahamas", pays)) %>%
  mutate(pays = gsub("^bh$", "Bahreïn", pays)) %>%
  mutate(pays = gsub("^bd$", "Bangladesh", pays)) %>%
  mutate(pays = gsub("^bb$", "Barbade", pays)) %>%
  mutate(pays = gsub("^by$", "Biélorussie", pays)) %>%
  mutate(pays = gsub("^be$", "Belgique", pays)) %>%
  mutate(pays = gsub("^bz$", "Belize", pays)) %>%
  mutate(pays = gsub("^bj$", "Bénin", pays)) %>%
  mutate(pays = gsub("^bm$", "Bermudes", pays)) %>%
  mutate(pays = gsub("^bt$", "Bhoutan", pays)) %>%
  mutate(pays = gsub("^bo$", "Bolivie", pays)) %>%
  mutate(pays = gsub("^bq$", "Pays-Bas caribéens", pays)) %>%
  mutate(pays = gsub("^ba$", "Bosnie-Herzégovine", pays)) %>%
  mutate(pays = gsub("^bw$", "Botswana", pays)) %>%
  mutate(pays = gsub("^bv$", "Île Bouvet", pays)) %>%
  mutate(pays = gsub("^br$", "Brésil", pays)) %>%
  mutate(pays = gsub("^bn$", "Brunei", pays)) %>%
  mutate(pays = gsub("^bg$", "Bulgarie", pays)) %>%
  mutate(pays = gsub("^bf$", "Burkina Faso", pays)) %>%
  mutate(pays = gsub("^bi$", "Burundi", pays)) %>%
  mutate(pays = gsub("^ky$", "Îles Caïmans", pays)) %>%
  mutate(pays = gsub("^kh$", "Cambodge", pays)) %>%
  mutate(pays = gsub("^cm$", "Cameroun", pays)) %>%
  mutate(pays = gsub("^ca$", "Canada", pays)) %>%
  mutate(pays = gsub("^cv$", "Cap-Vert", pays)) %>%
  mutate(pays = gsub("^cf$", "République centrafricaine", pays)) %>%
  mutate(pays = gsub("^cl$", "Chili", pays)) %>%
  mutate(pays = gsub("^cn$", "Chine", pays)) %>%
  mutate(pays = gsub("^cx$", "Île Christmas", pays)) %>%
  mutate(pays = gsub("^cy$", "Chypre", pays)) %>%
  mutate(pays = gsub("^cc$", "Îles Cocos", pays)) %>%
  mutate(pays = gsub("^co$", "Colombie", pays)) %>%
  mutate(pays = gsub("^km$", "Comores", pays)) %>%
  mutate(pays = gsub("^cg$", "République du Congo", pays)) %>%
  mutate(pays = gsub("^cd$", "République démocratique du Congo", pays)) %>%
  mutate(pays = gsub("^ck$", "Îles Cook", pays)) %>%
  mutate(pays = gsub("^kr$", "Corée du Sud", pays)) %>%
  mutate(pays = gsub("^kp$", "Corée du Nord", pays)) %>%
  mutate(pays = gsub("^cr$", "Costa Rica", pays)) %>%
  mutate(pays = gsub("^ci$", "Côte d'Ivoire", pays)) %>%
  mutate(pays = gsub("^hr$", "Croatie", pays)) %>%
  mutate(pays = gsub("^cu$", "Cuba", pays)) %>%
  mutate(pays = gsub("^cw$", "Curaçao", pays)) %>%
  mutate(pays = gsub("^dk$", "Danemark", pays)) %>%
  mutate(pays = gsub("^dj$", "Djibouti", pays)) %>%
  mutate(pays = gsub("^do$", "République dominicaine", pays)) %>%
  mutate(pays = gsub("^dm$", "Dominique", pays)) %>%
  mutate(pays = gsub("^eg$", "Égypte", pays)) %>%
  mutate(pays = gsub("^sv$", "Salvador", pays)) %>%
  mutate(pays = gsub("^ae$", "Émirats arabes unis", pays)) %>%
  mutate(pays = gsub("^ec$", "Équateur", pays)) %>%
  mutate(pays = gsub("^er$", "Érythrée", pays)) %>%
  mutate(pays = gsub("^es$", "Espagne", pays)) %>%
  mutate(pays = gsub("^ee$", "Estonie", pays)) %>%
  mutate(pays = gsub("^us$", "États-Unis", pays)) %>%
  mutate(pays = gsub("^et$", "Éthiopie", pays)) %>%
  mutate(pays = gsub("^fk$", "Malouines", pays)) %>%
  mutate(pays = gsub("^fo$", "Îles Féroé", pays)) %>%
  mutate(pays = gsub("^fj$", "Fidji", pays)) %>%
  mutate(pays = gsub("^fi$", "Finlande", pays)) %>%
  mutate(pays = gsub("^fr$", "France", pays)) %>%
  mutate(pays = gsub("^ga$", "Gabon", pays)) %>%
  mutate(pays = gsub("^gm$", "Gambie", pays)) %>%
  mutate(pays = gsub("^ge$", "Géorgie", pays)) %>%
  mutate(pays = gsub("^gs$", "Géorgie du Sud-et-les îles Sandwich du Sud", pays)) %>%
  mutate(pays = gsub("^gh$", "Ghana", pays)) %>%
  mutate(pays = gsub("^gi$", "Gibraltar", pays)) %>%
  mutate(pays = gsub("^gr$", "Grèce", pays)) %>%
  mutate(pays = gsub("^gd$", "Grenade", pays)) %>%
  mutate(pays = gsub("^gl$", "Groenland", pays)) %>%
  mutate(pays = gsub("^gp$", "Guadeloupe", pays)) %>%
  mutate(pays = gsub("^gu$", "Guam", pays)) %>%
  mutate(pays = gsub("^gt$", "Guatemala", pays)) %>%
  mutate(pays = gsub("^gg$", "Guernesey", pays)) %>%
  mutate(pays = gsub("^gn$", "Guinée", pays)) %>%
  mutate(pays = gsub("^gw$", "Guinée-Bissau", pays)) %>%
  mutate(pays = gsub("^gq$", "Guinée équatoriale", pays)) %>%
  mutate(pays = gsub("^gy$", "Guyana", pays)) %>%
  mutate(pays = gsub("^gf$", "Guyane", pays)) %>%
  mutate(pays = gsub("^ht$", "Haïti", pays)) %>%
  mutate(pays = gsub("^hm$", "Îles Heard-et-MacDonald", pays)) %>%
  mutate(pays = gsub("^hn$", "Honduras", pays)) %>%
  mutate(pays = gsub("^hk$", "Hong Kong", pays)) %>%
  mutate(pays = gsub("^hu$", "Hongrie", pays)) %>%
  mutate(pays = gsub("^im$", "Île de Man", pays)) %>%
  mutate(pays = gsub("^um$", "Îles mineures éloignées des États-Unis", pays)) %>%
  mutate(pays = gsub("^vg$", "Îles Vierges britanniques", pays)) %>%
  mutate(pays = gsub("^vi$", "Îles Vierges des États-Unis", pays)) %>%
  mutate(pays = gsub("^in$", "Inde", pays)) %>%
  mutate(pays = gsub("^id$", "Indonésie", pays)) %>%
  mutate(pays = gsub("^ir$", "Iran", pays)) %>%
  mutate(pays = gsub("^iq$", "Irak", pays)) %>%
  mutate(pays = gsub("^ie$", "Irlande", pays)) %>%
  mutate(pays = gsub("^is$", "Islande", pays)) %>%
  mutate(pays = gsub("^il$", "Israël", pays)) %>%
  mutate(pays = gsub("^it$", "Italie", pays)) %>%
  mutate(pays = gsub("^jm$", "Jamaïque", pays)) %>%
  mutate(pays = gsub("^jp$", "Japon", pays)) %>%
  mutate(pays = gsub("^je$", "Jersey", pays)) %>%
  mutate(pays = gsub("^jo$", "Jordanie", pays)) %>%
  mutate(pays = gsub("^kz$", "Kazakhstan", pays)) %>%
  mutate(pays = gsub("^ke$", "Kenya", pays)) %>%
  mutate(pays = gsub("^kg$", "Kirghizistan", pays)) %>%
  mutate(pays = gsub("^ki$", "Kiribati", pays)) %>%
  mutate(pays = gsub("^kw$", "Koweït", pays)) %>%
  mutate(pays = gsub("^la$", "Laos", pays)) %>%
  mutate(pays = gsub("^ls$", "Lesotho", pays)) %>%
  mutate(pays = gsub("^lv$", "Lettonie", pays)) %>%
  mutate(pays = gsub("^lb$", "Liban", pays)) %>%
  mutate(pays = gsub("^lr$", "Liberia", pays)) %>%
  mutate(pays = gsub("^ly$", "Libye", pays)) %>%
  mutate(pays = gsub("^li$", "Liechtenstein", pays)) %>%
  mutate(pays = gsub("^lt$", "Lituanie", pays)) %>%
  mutate(pays = gsub("^lu$", "Luxembourg", pays)) %>%
  mutate(pays = gsub("^mo$", "Macao", pays)) %>%
  mutate(pays = gsub("^mk$", "Macédoine du Nord", pays)) %>%
  mutate(pays = gsub("^mg$", "Madagascar", pays)) %>%
  mutate(pays = gsub("^my$", "Malaisie", pays)) %>%
  mutate(pays = gsub("^mw$", "Malawi", pays)) %>%
  mutate(pays = gsub("^mv$", "Maldives", pays)) %>%
  mutate(pays = gsub("^ml$", "Mali", pays)) %>%
  mutate(pays = gsub("^mt$", "Malte", pays)) %>%
  mutate(pays = gsub("^mp$", "Îles Mariannes du Nord", pays)) %>%
  mutate(pays = gsub("^ma$", "Maroc", pays)) %>%
  mutate(pays = gsub("^mh$", "Îles Marshall", pays)) %>%
  mutate(pays = gsub("^mq$", "Martinique", pays)) %>%
  mutate(pays = gsub("^mu$", "Maurice", pays)) %>%
  mutate(pays = gsub("^mr$", "Mauritanie", pays)) %>%
  mutate(pays = gsub("^yt$", "Mayotte", pays)) %>%
  mutate(pays = gsub("^mx$", "Mexique", pays)) %>%
  mutate(pays = gsub("^fm$", "États fédérés de Micronésie", pays)) %>%
  mutate(pays = gsub("^md$", "Moldavie", pays)) %>%
  mutate(pays = gsub("^mc$", "Monaco", pays)) %>%
  mutate(pays = gsub("^mn$", "Mongolie", pays)) %>%
  mutate(pays = gsub("^me$", "Monténégro", pays)) %>%
  mutate(pays = gsub("^ms$", "Montserrat", pays)) %>%
  mutate(pays = gsub("^mz$", "Mozambique", pays)) %>%
  mutate(pays = gsub("^mm$", "Birmanie", pays)) %>%
  mutate(pays = gsub("^na$", "Namibie", pays)) %>%
  mutate(pays = gsub("^nr$", "Nauru", pays)) %>%
  mutate(pays = gsub("^np$", "Népal", pays)) %>%
  mutate(pays = gsub("^ni$", "Nicaragua", pays)) %>%
  mutate(pays = gsub("^ne$", "Niger", pays)) %>%
  mutate(pays = gsub("^ng$", "Nigeria", pays)) %>%
  mutate(pays = gsub("^nu$", "Niue", pays)) %>%
  mutate(pays = gsub("^nf$", "Île Norfolk", pays)) %>%
  mutate(pays = gsub("^no$", "Norvège", pays)) %>%
  mutate(pays = gsub("^nc$", "Nouvelle-Calédonie", pays)) %>%
  mutate(pays = gsub("^nz$", "Nouvelle-Zélande", pays)) %>%
  mutate(pays = gsub("^io$", "Territoire britannique de l'océan Indien", pays)) %>%
  mutate(pays = gsub("^om$", "Oman", pays)) %>%
  mutate(pays = gsub("^ug$", "Ouganda", pays)) %>%
  mutate(pays = gsub("^uz$", "Ouzbékistan", pays)) %>%
  mutate(pays = gsub("^pk$", "Pakistan", pays)) %>%
  mutate(pays = gsub("^pw$", "Palaos", pays)) %>%
  mutate(pays = gsub("^ps$", "Palestine", pays)) %>%
  mutate(pays = gsub("^pa$", "Panama", pays)) %>%
  mutate(pays = gsub("^pg$", "Papouasie-Nouvelle-Guinée", pays)) %>%
  mutate(pays = gsub("^py$", "Paraguay", pays)) %>%
  mutate(pays = gsub("^nl$", "Pays-Bas", pays)) %>%
  mutate(pays = gsub("^pe$", "Pérou", pays)) %>%
  mutate(pays = gsub("^ph$", "Philippines", pays)) %>%
  mutate(pays = gsub("^pn$", "Îles Pitcairn", pays)) %>%
  mutate(pays = gsub("^pl$", "Pologne", pays)) %>%
  mutate(pays = gsub("^pf$", "Polynésie française", pays)) %>%
  mutate(pays = gsub("^pr$", "Porto Rico", pays)) %>%
  mutate(pays = gsub("^pt$", "Portugal", pays)) %>%
  mutate(pays = gsub("^qa$", "Qatar", pays)) %>%
  mutate(pays = gsub("^re$", "La Réunion", pays)) %>%
  mutate(pays = gsub("^ro$", "Roumanie", pays)) %>%
  mutate(pays = gsub("^gb$", "Royaume-Uni", pays)) %>%
  mutate(pays = gsub("^ru$", "Russie", pays)) %>%
  mutate(pays = gsub("^rw$", "Rwanda", pays)) %>%
  mutate(pays = gsub("^eh$", "République arabe sahraouie démocratique", pays)) %>%
  mutate(pays = gsub("^bl$", "Saint-Barthélemy", pays)) %>%
  mutate(pays = gsub("^kn$", "Saint-Christophe-et-Niévès", pays)) %>%
  mutate(pays = gsub("^sm$", "Saint-Marin", pays)) %>%
  mutate(pays = gsub("^mf$", "Saint-Martin", pays)) %>%
  mutate(pays = gsub("^sx$", "Saint-Martin", pays)) %>%
  mutate(pays = gsub("^pm$", "Saint-Pierre-et-Miquelon", pays)) %>%
  mutate(pays = gsub("^va$", "Saint-Siège (État de la Cité du Vatican)", pays)) %>%
  mutate(pays = gsub("^vc$", "Saint-Vincent-et-les-Grenadines", pays)) %>%
  mutate(pays = gsub("^sh$", "Sainte-Hélène, Ascension et Tristan da Cunha", pays)) %>%
  mutate(pays = gsub("^lc$", "Sainte-Lucie", pays)) %>%
  mutate(pays = gsub("^sb$", "Îles Salomon", pays)) %>%
  mutate(pays = gsub("^ws$", "Samoa", pays)) %>%
  mutate(pays = gsub("^as$", "Samoa américaines", pays)) %>%
  mutate(pays = gsub("^st$", "Sao Tomé-et-Principe", pays)) %>%
  mutate(pays = gsub("^sn$", "Sénégal", pays)) %>%
  mutate(pays = gsub("^rs$", "Serbie", pays)) %>%
  mutate(pays = gsub("^sc$", "Seychelles", pays)) %>%
  mutate(pays = gsub("^sl$", "Sierra Leone", pays)) %>%
  mutate(pays = gsub("^sg$", "Singapour", pays)) %>%
  mutate(pays = gsub("^sk$", "Slovaquie", pays)) %>%
  mutate(pays = gsub("^si$", "Slovénie", pays)) %>%
  mutate(pays = gsub("^so$", "Somalie", pays)) %>%
  mutate(pays = gsub("^sd$", "Soudan", pays)) %>%
  mutate(pays = gsub("^ss$", "Soudan du Sud", pays)) %>%
  mutate(pays = gsub("^lk$", "Sri Lanka", pays)) %>%
  mutate(pays = gsub("^se$", "Suède", pays)) %>%
  mutate(pays = gsub("^ch$", "Suisse", pays)) %>%
  mutate(pays = gsub("^sr$", "Suriname", pays)) %>%
  mutate(pays = gsub("^sj$", "Svalbard et ile Jan Mayen", pays)) %>%
  mutate(pays = gsub("^sz$", "Eswatini", pays)) %>%
  mutate(pays = gsub("^sy$", "Syrie", pays)) %>%
  mutate(pays = gsub("^tj$", "Tadjikistan", pays)) %>%
  mutate(pays = gsub("^tw$", "Taïwan / (République de Chine (Taïwan))", pays)) %>%
  mutate(pays = gsub("^tz$", "Tanzanie", pays)) %>%
  mutate(pays = gsub("^td$", "Tchad", pays)) %>%
  mutate(pays = gsub("^cz$", "Tchéquie", pays)) %>%
  mutate(pays = gsub("^tf$", "Terres australes et antarctiques françaises", pays)) %>%
  mutate(pays = gsub("^th$", "Thaïlande", pays)) %>%
  mutate(pays = gsub("^tl$", "Timor oriental", pays)) %>%
  mutate(pays = gsub("^tg$", "Togo", pays)) %>%
  mutate(pays = gsub("^tk$", "Tokelau", pays)) %>%
  mutate(pays = gsub("^to$", "Tonga", pays)) %>%
  mutate(pays = gsub("^tt$", "Trinité-et-Tobago", pays)) %>%
  mutate(pays = gsub("^tn$", "Tunisie", pays)) %>%
  mutate(pays = gsub("^tm$", "Turkménistan", pays)) %>%
  mutate(pays = gsub("^tc$", "Îles Turques-et-Caïques", pays)) %>%
  mutate(pays = gsub("^tr$", "Turquie", pays)) %>%
  mutate(pays = gsub("^tv$", "Tuvalu", pays)) %>%
  mutate(pays = gsub("^ua$", "Ukraine", pays)) %>%
  mutate(pays = gsub("^uy$", "Uruguay", pays)) %>%
  mutate(pays = gsub("^vu$", "Vanuatu", pays)) %>%
  mutate(pays = gsub("^ve$", "Venezuela", pays)) %>%
  mutate(pays = gsub("^vn$", "Viêt Nam", pays)) %>%
  mutate(pays = gsub("^wf$", "Wallis-et-Futuna", pays)) %>%
  mutate(pays = gsub("^ye$", "Yémen", pays)) %>%
  mutate(pays = gsub("^zm$", "Zambie", pays)) %>%
  mutate(pays = gsub("^zw$", "Zimbabwe", pays))

fin <- rD[["server"]]$stop()

write_csv(data_clean, paste("arwu-", year, ".csv", sep = ""))
message(paste("Data retrieved successfully. You'll find them in your working directory in arwu-", year, ".csv . See you!", sep = ""))
