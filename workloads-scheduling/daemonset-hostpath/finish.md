# Bravo !

Tu viens de conclure le chapitre Workloads & Scheduling avec les `DaemonSet` et les volumes `hostPath` :

1. **DaemonSet** : un pod garanti sur chaque nœud éligible, sans passer par un `Deployment` ni gérer soi-même le nombre de réplicas.
2. **hostPath** : chaque pod écrit sur le disque **local** de son propre nœud — pas un stockage partagé entre les pods du DaemonSet.
3. **Réconciliation continue** : contrairement à un `Deployment`, un `DaemonSet` réagit tout seul à un changement de `nodeSelector` — retirant automatiquement les pods des nœuds devenus inéligibles, sans `rollout restart`.
4. **hostPath et cycle de vie** : Kubernetes ne nettoie jamais un volume `hostPath` quand un pod disparaît — le répertoire reste sur le disque du nœud, orphelin, jusqu'à intervention manuelle.

## Points clés à retenir

- Un `DaemonSet` sans `nodeSelector` (ni `affinity`, ni `tolerations` particulières) cible tous les nœuds qui ne portent pas de taint bloquant — pas besoin de compter les nœuds ou de gérer un nombre de réplicas.
- Une boucle qui réécrit périodiquement un fichier est un bon réflexe pour distinguer, lors d'un diagnostic, "le pod ne tourne plus ici" de "le pod tourne mais n'écrit plus depuis un moment" — une simple absence de fichier ne suffit pas à elle seule si l'écriture n'est qu'ponctuelle.
- `hostPath` lie un pod aux données **du nœud sur lequel il tourne** : si ce pod est réordonnancé sur un autre nœud, ses anciennes données restent sur l'ancien nœud, inaccessibles au nouveau pod.

## Pour aller plus loin

- DaemonSet : https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/
- Volumes (hostPath) : https://kubernetes.io/docs/concepts/storage/volumes/#hostpath
