
# Bash-utils

Ce projet rassemble quelques fonctions et méthodes que j'utilise régulièrement.

## Usage
Pour l'utiliser, il faut sourcer le fichier bash-utils.sh :

```
source ./bash-utils.sh
utils:log log message test
```

![test](./test.png)

### Les fonctions
```
bash-utils.sh --help
Usage : bash-utils.sh [--help|<function name>]
Functions ('main' by default) : 
  - utils:blue : print parameters with blue background : parameters
  - utils:cyan : print parameters with cyan background : parameters
  - utils:debug : print parameters in blue : 🐛  parameters
  - utils:error : print parameters in red to stderr : ❌  parameters
  - utils:exec : print parameter with plue background and execute parameters
  - utils:green : print parameters with green background : parameters
  - utils:help : print the help of all functions (the declare help='...')
  - utils:hr : print N horizontal line, N=1 by default, N is the first parameter
  - utils:init : init bash options: errexit, nounset, pipefail, xtrace if TRACE==true, trap utils:print_stack_on_error if PRINT_STACK_ON_ERROR==true
  - utils:list_functions : list all functions of the parent script
  - utils:log : print parameters in green : ℹ️  parameters
  - utils:orange : print parameters with orange background : parameters
  - utils:pipe_blue : print each line of stdin with blue background : parameters
  - utils:pipe_cyan : print each line of stdin with cyan background : parameters
  - utils:pipe_debug : print each line of stdin in blue : 🐛  stdin
  - utils:pipe_error : print each line of stdin in red to stderr : ❌  stdin
  - utils:pipe_green : print each line of stdin with green background : parameters
  - utils:pipe_log : print each line of stdin in green : ℹ️  stdin
  - utils:pipe_orange : print each line of stdin with orange background : parameters
  - utils:pipe_purple : print each line of stdin with purple background : parameters
  - utils:pipe_red : print each line of stdin with red background : parameters
  - utils:pipe_warn : print each line of stdin in orange to stderr : ️⚠️  stdin
  - utils:pipe_white : print each line of stdin with white background : parameters
  - utils:print_stack_on_error : print stack on error exit
  - utils:print_template : print the stack on error exit
  - utils:purple : print parameters with purple background : parameters
  - utils:red : print parameters with red background : parameters
  - utils:run : run utils:init and run the main function or the function $1, add color and use utils:pipe_error for stderr except if PIPE_MAIN_STDERR!=true
  - utils:run_main : run utils:init and run the main function, add color and use utils:pipe_error for stderr except if PIPE_MAIN_STDERR!=true
  - utils:stack : print current stack
  - utils:warn : print parameters in orange to stderr : ️⚠️  parameters
  - utils:white : print parameters with white background : parameters
```

## Supprimer les usages bash-utils 
Il y un script qui permet de supprimer les usages des fonctions de `bash-utils.sh`
si jamais l'on veut supprimer cette dépendance à ce projet :
`remove_bash-utils.sh`

On peut ajouter les chemins vers les fichiers à traiter en paramètres :
```
./remove_bash-utils.sh my_script1.sh my_script2.sh
```
ou on peut tester une conversion :
```
< example.sh ./remove_bash-utils.sh > example_without_bash-utils.sh
```

Pour vérifier s'il reste des usages de fonctions utils:* :
```
grep -E "utils:[a-zA-Z0-9_]*" my_script.sh
```

Il faudra certainement corriger un peu le formatage du fichier modifié


## Bonnes pratiques d'écriture de scripts bash

**⚠ Disclaimer : les conseils indiqués ici sont de mon point de vue,
rien que dans les liens ci-dessous, les avis divergent quelques fois des miens et
ne sont pas unanimes sur tous les sujets.**


Ci-dessous, quelques bonnes pratiques acquises avec l'expérience mais surtout avec pas
mal de lectures du web, entre autre :
* https://kvz.io/bash-best-practices.html
* https://bertvv.github.io/cheat-sheets/Bash.html
* https://github.com/progrium/bashstyle
* http://google.github.io/styleguide/shellguide.html
* https://google.github.io/styleguide/shellguide.html
* https://wiki.bash-hackers.org/scripting/obsolete
* https://jvns.ca/blog/2017/03/26/bash-quirks/
* https://sap1ens.com/blog/2017/07/01/bash-scripting-best-practices/
* https://blog.yossarian.net/2020/01/23/Anybody-can-write-good-bash-with-a-little-effort
* http://mywiki.wooledge.org/BashFAQ/031


### Arrêter l'exécution dès la première erreur
Ajouter dans le script : `set -o errexit`, toutes les commandes qui auront un code de sortie différent de 0 stoperont le déroulement du script.

Cette règle est très importante. Par exemple :
```
cd my_folder
rm -rf *
```
Sans l'option `errexit`, ce script effacera tous les fichiers du dossier courant si `my_folder` n'existe pas, alors qu'il s'arreterait en erreur sur le `cd` s'il y avait eu un `set -o errexit` avant.

Si l'on veut autoriser une commande à sortir en erreur, il faut ajouter `|| true` après cette dernière : `my_func || true`

C'est l'équivalent plus long de  `set -e`. Privilégiez la version longue qui est plus explicite.


### Détecter les variables non initialisées
Ajouter dans le script : `set -o nounset` pour que le script s'arrete en erreur si une variable non initialisée est utilisée.

C'est l'équivalent plus long de  `set -u`. Privilégiez la version longue qui est plus explicite.

Penser à `${my_var:-}` pour initialiser my_var à une valeur vide (voir ci-dessous).

### Initialiser les variables qui ont le droit d'être non inialisées

Utiliser `${var:-default value}` pour définir une valeur par défaut si la variable
n'est pas initialisée
```
set -o nounset
directory=${DIRECTORY:-}
file=${FILE:-foo}
```
Sans ça, l'usage de `set -o nounset` arretera le script si une variable non initialisée est utilisée.

### Détecter les erreurs lorsque l'on utilise les pipes : `cmd1 | cmd2`
Ajouter dans le script : `set -o pipefail` pour que le code d'erreur soit celui de la première commande et non celle utilisée dans le pipe.

```
exit 1 | exit 0
echo $?
```
Ce script affichera 0 sans l'option `pipefail` et le script continura même si l'option `errexit` est activée, alors qu'avec l'option `pipefail`, le code affiché sera 1 et le script s'arretera si `errexit` est activé (le echo ne sera pas exécuté dans ce cas là car le script se sera arrêté sur le false).

### Mettre tout le code dans des fonctions

Permet de clarifier le code, exécuter une fonction en particulier, ...

### Utiliser une fonction main pour le code principal

### Utiliser `my_func() { ... }` plutot que `function my_func { ... }`

### Utiliser des variables plutôt que des paramètres

Plus discutable ! Mais très pratique, cela évite pas mal de code de gestion
des paramètres et avec l'option `set -o nounset`, on détecte facilement les
problèmes d'initialisation des variables.

Pour exécuter un script avec des variables, dans ce cas :
```
var1=value1 ./my_script.sh
```

```
my_func() {
  echo "${var1}${var2}"
}
foo(){
var1="b"
var2="ar"
my_func
}
```
et il est possible de lancer un script avec `var1=b var2=ar ./my_script.sh`.

L'équivalent avec des paramètres nommés est beaucoup plus longue:
```
my_func() {
  while [[ $# -gt 0 ]]
  do
    key="$1"
    case $key in
        --var1)
        var1="$2"
        shift
        shift
        ;;
        --var2)
        var2="$2"
        shift
        shift
        ;;
        *)
        shift
        ;;
    esac
  done
  echo "${var1}${var2}"
}
foo(){
  my_func --var2 "ar" --var1 "b"
}
```
Si on se base sur l'ordre des paramètres:
```
my_func() {
  var1="$1"
  var2="$2"
  echo "${var1}${var2}"
}
foo(){
  my_func "ar" "b"
}
```
Ça redevient plus cours mais il faut gérer l'ordre des paramètres et c'est moins clair coté appelant (le param numéro X correspond à quoi, ...).

### Détecter si le script est sourcé ou exécuté

N'exécuter main seulement si le script est exécuté et pas sourcé :
```
if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
  main "${@}"
fi
```

"sourcé" signifie `source ./my_script.sh` ou `. ./my_script.sh`, qui revient à importer le code en quelque sorte, il est exécuté en réalité, et ses fonctions sont alors dorénavant accéssibles.

### Utiliser snake_case pour les noms des variables et des fonctions

### `#!/usr/bin/env bash` plutôt que `#!/bin/bash`

### Utilise Shellcheck pour détecter les erreurs

### Utilise shfmt pour formater le code

### Utiliser un IDE pour écrire des scripts
Les IDE récents, notamment Intellij, permettent d'écrire du code bash en détectant
des erreurs potentielles et en formatant le code, comme n'importe quel langage.

shfmt et shellsheck sont inclus dans Intellij par exemple.

### Utiliser `trap` pour déclencher du code à la fin du script ou sur une erreur
```
trap cleanup EXIT ERR
```
cette ligne déclenchera l'exécution de la fonction `cleanup` lorsque le script se terminera.

Dans ce cas, pensez à bien propager le code de sortie (si c'est souhaité) :
```
cleanup() {
    exitcode=$?
    ...
    exit $exitcode
}
```

### Utiliser des namespaces

Bash ne propose pas de namespaces à proprement parler, mais on peut nommer les fonctions
avec un préfixe commun pour identifier les fonctions d'un script ou d'une partie donnée.

Le séparateur peut être `_` ou `:` par exemple :
```
mysh:print(){ ... }
mysh:foo(){ ... }
mysh:bar(){ ... }
```

### Faire des tests unitaires avec bats
https://github.com/bats-core/bats-core
```
@test "addition using bc" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}
```

### utiliser version longue des paramètres
`curl --show-error ...` plutot que `curl -S ...`

### Utiliser ${var} plutôt que $var

à nuancer

### Naviguer dans les dossiers depuis un subshell

```
(
 cd dir/
 do_something
)
```
plutôt que
```
cd dir/
do_something
cd ..
```

### Fonctions privées
Pour les fonctions qui ne sont pas destinées à être utilisées dans d'autres scripts,
On peut préfixer le nom de la fonction par `_` et ne pas utiliser de préfixe de namespace :
```
_my_private_function() {
}
my_script:my_func() {
  _my_private_function
}
```

## Astuces

### Activer l'affichage des commandes exécutées si TRACE=1
Placer `[[ ${TRACE:-0} != 1 ]] || set -o xtrace` dans le script pour activer l'affichage des lignes de code exécutées facilement.

Pour lancer le script en mode debug : `TRACE=1 ./my_script.sh`

`set -o xtrace` est la version longue de `set -x`

### Permettre l'exécution d'une fonction en particulier

Par exemple, si on passe des paramètres au script :
```
if [[ $# == 0 ]]; then # if the script has no argument, run the main() function
  main
else
  "$@"
fi
```
Si on exécute ce script avec `./my_script.sh test_function arg1 arg2`,
ça ne lancera que la fonction `test_function` avec les 2 paramètres.

C'est très pratique pour le dev, debug et les TU entre autre, ou pour proposer des fonctionnalité facilement depuis la ligne de commande.

### Pour documenter l'aide d'une fonction

```
my_func ()
{
    declare help="help message here";
    ...
}
eval "$(type my_func | grep 'declare help=')"
echo $help
```

### Pour les projets versionnés avec git
Vous pouvez
```
  GIT_TOPLEVEL=$(cd "${BASH_SOURCE[0]%/*}" && git rev-parse --show-toplevel)
```
Ensuite il est possible de se déplacer dans les dossier du projet ou référencer des fichiers de façon absolu, c'est pratique car en cas de déplacement d script, les chemins restent valides.


### Utiliser flock pour éxécuter une partie du code une seule fois en même temps

```
lock_file=/var/lock/my_script.lock
(
    echo "wait $lock_file"
    flock -x 200
    echo "→ got $lock_file"
    do stuff
    ...
) 200>"$lock_file"
```


## TODO list

* écrire la version anglaise du README
* permettre l'ajout de l'horodatage aux lignes de stderr et ou stdout
* proposer script/sed pour supprimer les fonctions utils:* qui pourrait être utilisées dans
un script où on voudrait enlever la dépendance :
  * remplacer les `log`/`warn`/... par des echo
  * supprimer les `utils:exec`
  * remplacer les `utils:run_main` par `main`
