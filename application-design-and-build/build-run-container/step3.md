# Étape 3 — Pousser l'image dans la registry locale

La registry `jedi-archives` est accessible à l'adresse **`localhost:5000`**. C'est elle-même un container :

`podman ps`{{exec}}

Elle est encore vide :

`curl -s localhost:5000/v2/_catalog`{{exec}}

## 1. Tagger l'image

Pour pousser une image vers une registry, son nom doit commencer par l'adresse de cette registry.

`podman tag r2d2:v1 localhost:5000/r2d2:v1`{{exec}}

`podman images`{{exec}}

Deux noms, un seul `IMAGE ID` : `podman tag` ne copie rien, il ajoute un nom.

## 2. Pousser l'image

`podman push localhost:5000/r2d2:v1`{{exec}}

Cette registry parle HTTP, sans TLS : elle est déclarée `insecure` dans `/etc/containers/registries.conf.d/99-scenario.conf`. Sans cela, il faudrait ajouter `--tls-verify=false` au `podman push`.

## 3. Interroger la registry

`curl -s localhost:5000/v2/_catalog`{{exec}}

`curl -s localhost:5000/v2/r2d2/tags/list`{{exec}}

Le dépôt `r2d2` et son tag `v1` sont dans la registry.
