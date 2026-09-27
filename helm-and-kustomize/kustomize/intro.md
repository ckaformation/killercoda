# Kustomize — base et overlays multi-région

Un répertoire `~/kustomize-multi-region/` est déjà en place :

- `base/` : un `Deployment`, un `Service` et un `ConfigMap` génériques
  (`region-service`), qui affiche la région lue dans le `ConfigMap`.
- `overlays/europe-west1/` : un premier overlay, encore incomplet.

Tu vas compléter et déployer cet overlay, en créer un second pour
`us-west1`, puis apprendre à retirer proprement une ressource
partagée entre plusieurs overlays.

Le cluster se prépare en arrière-plan pendant que tu lis ces lignes.
