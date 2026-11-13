# Bravo !

Tu as :

- Extrait les logs de tous les conteneurs d'un pod multi-conteneurs
  en une seule commande (`kubectl logs --all-containers`).
- Diagnostiqué un conflit de port entre deux conteneurs partageant le
  même espace réseau (le même pod).
- Corrigé le déploiement en remplaçant un conteneur par un autre,
  configuré pour écouter sur un port différent.

## Pour aller plus loin

- Pourquoi les conteneurs d'un même pod partagent-ils le même espace
  réseau, contrairement à des conteneurs de pods différents ?
  (indice : la "pause" / infra container)
- `kubectl logs <pod> -c <conteneur> --previous` : utile pour
  récupérer les logs d'un conteneur juste avant son dernier
  redémarrage, notamment en cas de `CrashLoopBackOff`.
- Quels autres cas classiques provoquent ce genre de conflit dans un
  pod multi-conteneurs (sidecars, exporters de métriques...) ?
