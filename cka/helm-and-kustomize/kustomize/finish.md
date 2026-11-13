# Bravo !

Tu as :

- Construit et complété un overlay Kustomize à partir d'une base
  partagée, en isolant la configuration spécifique à un environnement
  dans un seul fichier patché (`configmap-patch.yaml`).
- Dupliqué cet overlay pour un second environnement, en ne touchant
  que le strict nécessaire (`kustomization.yaml` + `ConfigMap`).
- Découvert une limite importante de `kubectl apply` : retirer une
  ressource du manifest ne la supprime jamais du cluster — il faut la
  supprimer explicitement, dans chaque environnement concerné.

## Pour aller plus loin

- `kubectl diff -k <overlay>` : montre ce qui changerait avant
  d'appliquer, y compris les ressources qui ne seraient plus gérées.
- `kubectl apply -k <overlay> --prune -l <label>` : une façon
  d'automatiser la suppression des ressources retirées du manifest,
  à condition d'étiqueter soigneusement toutes les ressources
  concernées — plus risqué si mal configuré.
- Que se passerait-il si tu avais utilisé un `configMapGenerator`
  plutôt qu'un patch direct ? Le nom du `ConfigMap` changerait à
  chaque valeur différente (suffixe de hash), et Kustomize mettrait à
  jour la référence dans le `Deployment` automatiquement.
