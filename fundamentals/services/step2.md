# Étape 2 — Exposer le Deployment avec un Service

## 1. Créer le Service

Complète la commande suivante (elle n'est pas cliquable : remplace chaque `<A_COMPLETER>` avant de l'exécuter) :

```
k expose deployment <A_COMPLETER> --port=<A_COMPLETER>
```

Utilise le nom du Deployment, `echo-base`, et le port `80`. Le Service créé porte le même nom que le Deployment.

## 2. Observer le Service

`k get svc -o wide`{{exec}}

Le Service `echo-base` est de type `ClusterIP`. Regarde ses colonnes :

- `CLUSTER-IP` : une adresse **virtuelle et stable**, qui ne change pas tant que le Service existe, même si les pods derrière lui sont remplacés ;
- `PORT(S)` : le port sur lequel le Service écoute (`80/TCP`) ;
- `SELECTOR` : les labels que doivent porter les pods pour être exposés (on y revient plus bas).

Tu vois aussi un Service `kubernetes` : c'est celui de l'API server, créé automatiquement.

## 3. Appeler le Service par sa CLUSTER-IP

Note la `CLUSTER-IP` de `echo-base`. Complète ensuite la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` par cette adresse avant de l'exécuter) :

```
curl <A_COMPLETER>
```

Ça fonctionne, avec une adresse qui ne dépend plus d'un pod en particulier.

Relance plusieurs appels d'affilée, avec la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` par la `CLUSTER-IP`) :

```
for i in 1 2 3 4 5 6 7 8 9 10; do curl -s <A_COMPLETER>; done
```

Tu dois voir **plusieurs noms de pods différents** : le Service répartit les appels entre les pods (la répartition n'est pas forcément régulière).

## 4. Comprendre quels pods sont exposés

Un Service ne connaît pas « un Deployment » : il expose les pods dont les **labels correspondent à son selector**. `k expose` a recopié le selector du Deployment, `app=echo-base`.

`k get pods --show-labels`{{exec}}

Les 3 pods portent le label `app=echo-base`. Tout pod du namespace portant ce label serait exposé par le Service, qu'il vienne ou non de ce Deployment ; un pod qui ne le porte pas ne le serait pas.

`k describe svc echo-base`{{exec}}

Repère les lignes `Selector` et `Endpoints` : les `Endpoints` sont les adresses des pods sélectionnés. Compare-les aux adresses de `k get pods -o wide` : ce sont les mêmes. Kubernetes tient cette liste à jour automatiquement.
