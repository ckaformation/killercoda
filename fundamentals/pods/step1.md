# Étape 1 — Créer un pod et l'inspecter

`k run` est la façon la plus directe de créer un pod : il n'y a ni Deployment ni ReplicaSet derrière, juste un pod « nu ».

## 1. Créer le pod

Complète la commande suivante (elle n'est pas cliquable : remplace chaque `<A_COMPLETER>` avant de l'exécuter) :

```
k run <A_COMPLETER> --image=<A_COMPLETER>
```

Utilise le nom `bb-8` et l'image `nginx:alpine`.

## 2. Attendre qu'il soit prêt

`k get pod bb-8`{{exec}}

Le pod passe d'abord par `ContainerCreating` (le temps de télécharger l'image), puis par `Running`.

`k wait --for=condition=Ready pod/bb-8 --timeout=90s`{{exec}}

## 3. Inspecter le pod avec describe

`k describe pod bb-8`{{exec}}

Parcours la sortie. Les rubriques les plus utiles :

- `Node` : le node qui héberge le pod (note-le, on y revient à l'étape suivante) ;
- `IP` : l'adresse du pod, partagée par tous ses containers ;
- `Containers` : l'image, l'état (`State`), `Ready` et `Restart Count` de chaque container ;
- `Events`, tout en bas : l'historique de la vie du pod (`Scheduled`, `Pulling`, `Pulled`, `Created`, `Started`). C'est le scheduler qui a choisi un node, puis le kubelet de ce node qui a téléchargé l'image et démarré le container.

## 4. Lire les logs du pod

`k logs bb-8`{{exec}}

Tu vois ce que le container écrit sur sa sortie standard : ici, les messages de démarrage de nginx.
