# SCRAPARWU

Ce script R permet de scraper le classement de Shanghaï depuis sa création en 2003. Il scrapera également l'année actuelle une fois que les résultats auront été publiés sur le site [shanghairanking.com](https://www.shanghairanking.com/rankings/arwu/2023).

## Utilisation

### Prérequis

Le script nécessite les *packages* suivant :

- tydiverse ;
- RSelenium ;
- rvest ;
- wdman ;
- binman ;
- netstat ;
- writexl.

Il est possible de retrouver la documentation pour ces *packages* sur le site du [CRAN](https://cran.r-project.org/web/packages/available_packages_by_name.html). Certains *packages*, comme RSelenium, requièrent l'installation de Java.

Si vous n'avez jamais installé rvest et RSelenium et jamais scrapé avec R auparavant, je recommande le visionnage de [cette vidéo explicative](https://www.youtube.com/watch?v=GnpJujF9dBw).

Enfin, le navigateur Chrome est requis. Pour l'installer : [https://www.google.com/intl/fr/chrome/](https://www.google.com/intl/fr/chrome/).

### Variables

Dans le script, la variable `naver` doit être réglée sur les trois premiers chiffres de votre version de Chrome. Pour les trouver :

- ouvrez le navigateur Chrome et rendez-vous à cette adresse : [chrome://version/](chrome://version/) ;
- le numéro de version se trouve tout en haut de la page :

![récupérez les trois premiers chiffres du numéro de version de votre navigateur Chrome](docs/chrome-version.png)

## Auteur et licence

**Auteur :** [@deroudilhep](https://github.com/deroudilhep) pour AEF info

**Licence :** [MIT](https://choosealicense.com/licenses/mit/)
