# Étape 2 — Upgrade falco

La release `falco` (namespace `falco`) est actuellement configurée
avec `falco.log_level` sur `warning`. Vérifie-le si tu veux :

```
helm get values falco -n falco
```{{exec}}

Fais un `helm upgrade` pour passer ce niveau de log à `debug` :

```
helm upgrade falco falcosecurity/falco --namespace falco --set falco.log_level=debug
```{{exec}}

Vérifie :

```
helm get values falco -n falco
```{{exec}}

```
helm history falco -n falco
```{{exec}}
