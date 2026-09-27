# Bravo !

Tu as pratiqué les 3 opérations de base du cycle de vie d'une release
Helm :

- `helm install` — avec `--create-namespace` et `--set` pour
  personnaliser une valeur au moment de l'installation.
- `helm upgrade` — pour changer une valeur sur une release existante.
- `helm rollback` — pour revenir au contenu d'une révision
  précédente.

## Deux points à retenir

- **`helm rollback <release> 1` ne "efface" pas l'historique** : il
  crée une **nouvelle** révision (ici, la 3), dont le contenu
  correspond à celui de la révision 1. `helm history` montre donc 3
  révisions, pas un retour à 1 seule.
- **`helm upgrade ... --set X=Y` sans `--reuse-values` repart des
  valeurs par défaut du chart**, pas de celles actuellement
  déployées : seul `X=Y` est appliqué en plus des défauts, ce qui
  peut réinitialiser silencieusement d'autres valeurs précédemment
  personnalisées (ici, `driver.kind`, positionné sur `modern_ebpf`
  au moment de l'installation initiale). `--reuse-values` (ou
  `-f values.yaml` avec un fichier complet) évite cet effet de bord.

## Pour aller plus loin

- `helm get values falco -n falco -a` : affiche toutes les valeurs
  (y compris celles par défaut du chart), pas seulement celles
  explicitement définies.
- `helm diff` (plugin externe) : montre precisément ce qu'un
  `upgrade` ou un `rollback` va changer, avant de l'exécuter.
