# Étape 2 — Ajouter une clé au Secret et faire un rollout

## 1. Ajouter une nouvelle clé au Secret

`kubectl edit secret death-star-plans-credentials`{{exec}}

Le champ `data` affiche les valeurs existantes encodées en base64 — pas pratique pour en ajouter une à la main. Plus simple : ajoute un champ `stringData` **au même niveau que `data`**, avec ta nouvelle clé en clair :

```yaml
stringData:
  token: holocron-x7
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`. Kubernetes encode automatiquement `stringData` en base64 et le fusionne dans `data`.

## 2. Constater que rien ne change... pour l'instant

`POD=$(kubectl get pod -l app=death-star-plans -o jsonpath='{.items[0].metadata.name}') && kubectl exec "$POD" -c nginx -- ls /config`{{exec}}

Toujours seulement `username` et `password` : pas de `token`. Deux raisons se combinent :

- le volume monté depuis le Secret finit par se synchroniser avec du retard, mais ce n'est pas le vrai problème ici ;
- surtout, l'**init container ne s'exécute qu'une seule fois**, au tout premier démarrage du pod. Modifier le Secret ne le fait pas repasser : il n'y a personne pour relancer le `cp`.

## 3. Déclencher un rollout

Pour qu'un nouveau pod naisse — et donc qu'un init container tourne à nouveau, avec le Secret à jour — il faut forcer un rollout :

`kubectl rollout restart deployment/death-star-plans`{{exec}}

`kubectl rollout status deployment/death-star-plans`{{exec}}

## 4. Vérifier

`POD=$(kubectl get pod -l app=death-star-plans -o jsonpath='{.items[0].metadata.name}') && kubectl exec "$POD" -c nginx -- cat /config/token`{{exec}}

Doit maintenant afficher `holocron-x7`.
