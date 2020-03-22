
# Bash-utils

Ce projet rassemble quelques fonctions et méthodes que j'utilise régulièrement.

## Usage
Pour l'utiliser, il faut sourcer le fichier bash-utils.sh : `source ./bash-utils.sh`

Ensuite, les fonctions `utils:*` sont disponibles, par exemple : `utils:log log message test`

![test](doc/test.png)

### Les fonctions
./bash-utils.sh --help donne :
`Usage : bash-utils.sh [--help | script_function_name [ARGS]...]`
et :

Functions ('main' by default) :
  - utils:countdown
  - utils:debug : print parameters in blue : 🐛  parameters
  - utils:error : print parameters in red to stderr : ❌  parameters
  - utils:exec : print parameter with blue background and execute parameters, print time if UTILS_PRINT_TIME=true
  - utils:flock_exec : run <$2 ...> command with flock (mutex) on '/var/lock/$1.lock' file
  - utils:get_param : same as 'utils:get_params' but return the first result only
  - utils:get_params : print parameter value $1 from "$@", if $1 == '--' print last parameters that doesn't start with by '-' ---- ='e|error' return 'value' for '--error=value' or '-e=value' ---- accept '--error value' and '-e value' if ='e |error '
  - utils:has_param : same as 'utils:get_params' but return exit code 0 if the key is found, 1 otherwise
  - utils:help : print the help of all functions (the declare help='...')
  - utils:hr : print N horizontal line, N=1 by default, N is the first parameter
  - utils:init : init bash options: errexit, nounset, pipefail, xtrace if TRACE==true, trap _utils_print_stack_and_exit_code if UTILS_PRINT_STACK_ON_ERROR==true
  - utils:list_functions : utils_params_values all functions of the parent script
  - utils:log : print parameters in green : ℹ️  parameters
  - utils:parse_parameters : set utils_params array from "$@" : --error=msg -a=123 -zer=5 opt1 'opt 2' -- file --opt3 →→ utils_params = [error]=msg ; [--]=opt1 / opt 2 / file / --opt3 ; [z]=5 ; [r]=5 ; [e]=5 ; [a]=123 (/ is \n here)
  - utils:print_template : print the stack on error exit
  - utils:run : run utils:init and run the main function or the function $1, add color and use utils:pipe utils:error for stderr except if PIPE_MAIN_STDERR!=true
  - utils:stack : print current stack
  - utils:warn : print parameters in orange to stderr : ️⚠️  parameters

## Les variables d'environnement

TODO

  - UTILS_DEBUG
  - UTILS_DEBUG_PIPES
  - UTILS_ZENITY_DEBUG
  - UTILS_PRINT_STACK_ON_ERROR
  - TRACE
  - UTILS_TRACE
  - UTILS_PRINTF_ENDLINE
  - UTILS_HIDE_PRIVATE_FUNCTIONS
  - IGNORE_UTILS_FUNCTIONS

TODO

## Supprimer les usages de bash-utils.sh
Il y un script qui permet de supprimer les usages des fonctions de `bash-utils.sh`
si jamais l'on veut supprimer cette dépendance à ce projet : `remove_bash-utils.sh`

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

## Bonnes pratiques d'écriture de scripts bash

**⚠ Disclaimer : les pratiques indiquées ici sont considérées bonnes de mon point de vue,
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
Ajouter au début du script : `set -o errexit`, toutes les commandes qui auront un code de sortie différent de 0 stopperont le déroulement du script.

Cette règle est très importante. Par exemple :
```
cd my_folder
rm -rf *
```
Sans l'option `errexit`, ce script effacera tous les fichiers du dossier courant si `my_folder` n'existe pas, alors qu'il s'arrêterait
en erreur sur le `cd` s'il y avait eu un `set -o errexit` avant.

Autre exemple :
```
#!/usr/bin/env bash

test_func() {
  echo "→ test_func begin"
  UNKNOWN_COMMAND_TO_PRODUCE_ERROR
  echo "← test_func end"
}

echo '---------------------- begin ---------------------'
test_func
set -o errexit
echo '------------------- errexit on -------------------'
test_func
echo '----------------------- end ----------------------'
```
Va produire cette sortie :
```
---------------------- begin ---------------------
→ test_func begin
./test.sh: ligne 6: UNKNOWN_COMMAND_TO_PRODUCE_ERROR : commande introuvable
← test_func end
------------------- errexit on -------------------
→ test_func begin
./test.sh: ligne 6: UNKNOWN_COMMAND_TO_PRODUCE_ERROR : commande introuvable
```

Si l'on veut autoriser une commande à sortir en erreur, il faut ajouter `|| true` après cette dernière : `my_func || true` :
```
#!/usr/bin/env bash

set -o errexit

test_func() {
  echo "→ test_func begin"
  UNKNOWN_COMMAND_TO_PRODUCE_ERROR || true
  echo "← test_func end"
}

echo '------------------- 1 -------------------'
test_func
echo '------------------- 2 -------------------'
```
Va produire cette sortie :
```
------------------- 1 -------------------
→ test_func begin
./t.sh: ligne 7: UNKNOWN_COMMAND_TO_PRODUCE_ERROR : commande introuvable
← test_func end
------------------- 2 -------------------
```

`set -o errexit` est l'équivalent plus long de `set -e`. Privilégiez la version longue qui est plus explicite.

#### ATTENTION, cette options n'est pas active dans certains cas

cf le man de bash :
```
The shell does not exit if the command that fails  is  part  of  the command list immediately following
a while or until keyword, part of the test following the if or elif reserved words, part of any command
executed in a && or || list except the command following the final && or ||, any command in a pipeline
but the last, or if the command's return value is being inverted with !.
If a compound command other than a subshell returns a non-zero status because  a command  failed
while -e was being ignored, the shell does not exit.
A trap on ERR, if set, is executed before the shell exits.  This option applies to the shell environment
and each subshell environment separately (see COMMAND EXECUTION ENVIRONMENT above),
and may cause subshells to exit before executing all the commands in the subshell.
If a compound command or shell function executes in a context where -e is being ignored, none of the
commands executed within the compound command or function body will be affected by the -e setting,
even if -e is set and a command returns a failure status.  If a compound command or shell function
sets -e while executing in a context where -e is ignored, that setting will not have any effect until the
compound command or the command containing the function call completes.
```
Donc, attention, `errexit` ne marchera pas pour le code d'une fonction dont l'appel est suivi
de `||` ou `&&` ou inclus dans un if ! Par exemple :
```
#!/usr/bin/env bash

set -o errexit

test_func() {
  echo "→ test_func begin" >&2 # stderr
  UNKNOWN_COMMAND_TO_PRODUCE_ERROR
  echo "← test_func end" >&2 # stderr
}

echo 'test_func || echo "err_||"'
test_func || echo "err_||"

echo '------------------- 1 -------------------'
echo 'if ! test_func ; then echo "err_if"; fi :'
if test_func ; then echo "err_if"; fi

echo '------------------- 2 -------------------'
echo 'out=$(test_func)  # [inherit_errexit off]'
out=$(test_func)
echo "1 - exitcode=$?"

echo '------------------- 3 -------------------'
shopt -s inherit_errexit
echo 'out=$(test_func)  # [inherit_errexit on]'
out=$(test_func)
echo "2 - exitcode=$?"
```
Va produire cette sortie :
```
test_func || echo "err_||"
→ test_func begin
./test.sh: ligne 7: UNKNOWN_COMMAND_TO_PRODUCE_ERROR : commande introuvable
← test_func end
------------------- 1 -------------------
if ! test_func ; then echo "err_if"; fi :
→ test_func begin
./test.sh: ligne 7: UNKNOWN_COMMAND_TO_PRODUCE_ERROR : commande introuvable
← test_func end
err_if
------------------- 2 -------------------
out=$(test_func)  # [inherit_errexit off]
→ test_func begin
./test.sh: ligne 7: UNKNOWN_COMMAND_TO_PRODUCE_ERROR : commande introuvable
← test_func end
1 - exitcode=0
------------------- 3 -------------------
out=$(test_func)  # [inherit_errexit on]
→ test_func begin
./test.sh: ligne 7: UNKNOWN_COMMAND_TO_PRODUCE_ERROR : commande introuvable
```
On voit bien que malgré le `set -o errexit`, le `echo "← test_func end"` est atteint dans les
2 premiers appels de `test_func`, malgré le `UNKNOWN_COMMAND_TO_PRODUCE_ERROR` (qui a un code de sortie de 127) !

#### inherit_errexit
On peut aussi voir, dans ce dernier exemple,que le `shopt -s inherit_errexit` fait arrêter le script sur le `out=$(test_func)`
alors que sans cette option, le script continu.

#### pour récupérer le code de sortie malgré le errexit

Si l'option `errexit` est activée, on ne peut pas obtenir le code de sortie de la précédente commande avec `$?`, car
si ce code de sortie est différent de 0, le script s'arrete en erreur...

une astuce consiste alors à utiliser `!` devant la commande, qui autorise la commande à échouer,
mais où on peut alors récupérer le code de sortie dans `${PIPESTATUS[0]}`:
```
#!/usr/bin/env bash

set -o errexit

  (exit 0)
echo "  (exit 0)  → \$?=$? -- \${PIPESTATUS[0]}=${PIPESTATUS[0]}"

! (exit 0)
echo "! (exit 0)  → \$?=$? -- \${PIPESTATUS[0]}=${PIPESTATUS[0]}"

! (exit 15)
echo "! (exit 15) → \$?=$? -- \${PIPESTATUS[0]}=${PIPESTATUS[0]}"
```
Va produire cette sortie :
```
  (exit 0)  → $?=0 -- ${PIPESTATUS[0]}=0
! (exit 0)  → $?=1 -- ${PIPESTATUS[0]}=0
! (exit 15) → $?=0 -- ${PIPESTATUS[0]}=15
```
`${PIPESTATUS[0]}` contient bien le code de sortie souhaité. Le fonctionnement de `PIPESTATUS` est décrit plus bas.

Attention, les remarque du paragraphe `cette options n'est pas active dans certains cas`
s'appliquent aussi à `! commande`

### Détecter les variables non initialisées
Ajouter dans le script : `set -o nounset` pour que le script s'arrete en erreur si une variable non initialisée est utilisée.

C'est l'équivalent plus long de `set -u`. Privilégiez la version longue qui est plus explicite.

Penser à `${my_var:-}` pour initialiser my_var à une valeur vide ou non définie (voir ci-dessous).



### Initialiser les variables qui ont le droit d'être non initialisées

Utiliser `${var:-default value}` pour définir une valeur par défaut si la variable
n'est pas initialisée
```
set -o nounset
directory=${DIRECTORY:-}
file=${FILE:-foo}
```
Sans ça, l'usage de `set -o nounset` arrêtera le script si une variable non initialisée est utilisée.

### Détecter les erreurs lorsque l'on utilise les pipes : `cmd1 | cmd2`
Ajouter dans le script : `set -o pipefail` pour que le code d'erreur soit celui de la première
commande et non celle utilisée dans le pipe.

Pour :
```
exit 1 | exit 0
echo $?
```
Sans l'option `pipefail` et le script continuera même si l'option `errexit` est activée car le code de retour considéré sera celui de `exit 0`,
alors qu'avec l'option `pipefail`, le code de sortie sera 1 et le script s'arretera alors si `errexit` est activé
(le `echo` ne sera pas exécuté dans ce cas là car le script se sera arrêté sur le `exit 1`).

```
#!/usr/bin/env bash

echo 'UNKNOWN_COMMAND_TO_PRODUCE_ERROR | true   # pipefail off -- errexit off'
UNKNOWN_COMMAND_TO_PRODUCE_ERROR | true
echo "exitcode=$? - \$PIPESTATUS=$PIPESTATUS"

set -o pipefail

echo 'UNKNOWN_COMMAND_TO_PRODUCE_ERROR | true   # pipefail on -- errexit off'
UNKNOWN_COMMAND_TO_PRODUCE_ERROR | true
echo "exitcode=$? - \$PIPESTATUS=$PIPESTATUS"

set +o pipefail
set -o errexit

echo 'UNKNOWN_COMMAND_TO_PRODUCE_ERROR | true   # pipefail off -- errexit on'
UNKNOWN_COMMAND_TO_PRODUCE_ERROR | true
echo "exitcode=$? - \$PIPESTATUS=$PIPESTATUS"

set -o pipefail

echo 'UNKNOWN_COMMAND_TO_PRODUCE_ERROR | true   # pipefail on -- errexit on'
UNKNOWN_COMMAND_TO_PRODUCE_ERROR | true
echo "exitcode=$? - \$PIPESTATUS=$PIPESTATUS"
```
Va produire cette sortie :
```
UNKNOWN_COMMAND_TO_PRODUCE_ERROR | true   # pipefail off -- errexit off
./test.sh: ligne 4: UNKNOWN_COMMAND_TO_PRODUCE_ERROR : commande introuvable
exitcode=0 - $PIPESTATUS=127
UNKNOWN_COMMAND_TO_PRODUCE_ERROR | true   # pipefail on -- errexit off
./test.sh: ligne 10: UNKNOWN_COMMAND_TO_PRODUCE_ERROR : commande introuvable
exitcode=127 - $PIPESTATUS=127
UNKNOWN_COMMAND_TO_PRODUCE_ERROR | true   # pipefail off -- errexit on
./test.sh: ligne 17: UNKNOWN_COMMAND_TO_PRODUCE_ERROR : commande introuvable
exitcode=0 - $PIPESTATUS=127
UNKNOWN_COMMAND_TO_PRODUCE_ERROR | true   # pipefail on -- errexit on
./test.sh: ligne 23: UNKNOWN_COMMAND_TO_PRODUCE_ERROR : commande introuvable
```

#### PIPESTATUS
à noter que la variable `$PIPESTATUS` contient le code de retour de la commande à droite du pipe.
C'est même un tableau :
```
#!/usr/bin/env bash
exit 0 | exit 1 | exit 2 | exit 3
echo "exit 0 | exit 1 | exit 2 | exit 3 : exitcode=$? - \$PIPESTATUS=${PIPESTATUS[@]}"
exit 0 | exit 1
echo "exit 0 | exit 1 : exitcode=$? - \$PIPESTATUS=${PIPESTATUS[@]}"
exit 1 | exit 0
echo "exit 1 | exit 0 : exitcode=$? - \$PIPESTATUS=${PIPESTATUS[@]}"

echo '→ set -o pipefail'

exit 0 | exit 1 | exit 2 | exit 3
echo "exit 0 | exit 1 | exit 2 | exit 3 : exitcode=$? - \$PIPESTATUS=${PIPESTATUS[@]}"
exit 0 | exit 1
echo "exit 0 | exit 1 : exitcode=$? - \$PIPESTATUS=${PIPESTATUS[@]}"
exit 1 | exit 0
echo "exit 1 | exit 0 : exitcode=$? - \$PIPESTATUS=${PIPESTATUS[@]}"
```
Va produire cette sortie :
```
exit 0 | exit 1 | exit 2 | exit 3 : exitcode=3 - $PIPESTATUS=0 1 2 3
exit 0 | exit 1 : exitcode=1 - $PIPESTATUS=0 1
exit 1 | exit 0 : exitcode=0 - $PIPESTATUS=1 0
→ set -o pipefail
exit 0 | exit 1 | exit 2 | exit 3 : exitcode=3 - $PIPESTATUS=0 1 2 3
exit 0 | exit 1 : exitcode=1 - $PIPESTATUS=0 1
exit 1 | exit 0 : exitcode=0 - $PIPESTATUS=1 0
```



### Mettre tout le code dans des fonctions

Permet de clarifier le code, exécuter une fonction en particulier, ...

### Utiliser une fonction main pour le code principal

### Utiliser `my_func() { ... }` plutôt que `function my_func { ... }`

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

L'équivalent avec des paramètres nommés est beaucoup plus longue :
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
Si on se base sur l'ordre des paramètres :
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
Ça redevient plus cours mais il faut gérer l'ordre des paramètres et c'est moins clair coté
appelant (le param numéro X correspond à quoi, ...).

### Détecter si le script est sourcé ou exécuté

N'exécuter main seulement si le script est exécuté et pas sourcé :
```
if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
  main "${@}"
fi
```

"sourcé" signifie `source ./my_script.sh` ou `. ./my_script.sh`, qui revient à importer le code en
quelque sorte, il est exécuté en réalité, et ses fonctions sont alors dorénavant accessibles.

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
`curl --show-error ...` plutôt que `curl -S ...`

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
Placer `[[ ${TRACE:-0} != 1 ]] || set -o xtrace` dans le script pour activer l'affichage
des lignes de code exécutées facilement.

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

C'est très pratique pour le dev, debug et les TUs entre autre, ou pour proposer des
fonctionnalités facilement depuis la ligne de commande.

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
Ensuite il est possible de se déplacer dans les dossiers du projet ou référencer des fichiers de façon
absolu, c'est pratique car en cas de déplacement d script, les chemins restent valides.


### Utiliser flock pour exécuter une partie du code une seule fois en même temps

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
* ajout de "local" dans les bonnes pratiques
* traiter les TODO du code

