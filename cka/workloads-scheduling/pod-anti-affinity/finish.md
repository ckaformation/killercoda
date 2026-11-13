# Bravo !

Tu viens d'explorer la pod anti-affinity, symétrique de la pod affinity vue dans `pod-affinity` :

1. **Pod anti-affinity** : `luke`, créé avec une anti-affinity ciblant `app=yoda`, s'est placé sur `controlplane` — le seul nœud sans pod correspondant.
2. **`IgnoredDuringExecution` en pratique** : ajouter `yoda-2` sur `controlplane` n'a **pas** évincé `luke`, déjà en place — la contrainte n'est vérifiée qu'au moment du scheduling, jamais réévaluée après coup pour un pod déjà démarré.
3. **Saturation complète** : une fois `luke` supprimé et recréé (donc de nouveau soumis au scheduling), plus aucun nœud ne satisfait sa contrainte — les deux portent désormais un pod `app=yoda`. Il reste `Pending` indéfiniment, jusqu'à ce que la situation change (libération d'un nœud, ou contrainte assouplie).

## Points clés à retenir

- La pod anti-affinity est l'exact miroir de la pod affinity : même structure (`labelSelector` + `topologyKey`), mais elle repousse au lieu d'attirer.
- `IgnoredDuringExecution` n'est pas qu'un détail de nommage : c'est une garantie concrète que Kubernetes ne va **jamais** évincer un pod déjà en place simplement parce qu'une règle d'affinité ou d'anti-affinité serait désormais violée. Seul un nouveau scheduling (recréation du pod) réévalue la contrainte.
- Un pod `Pending` sans nœud disponible n'est pas une erreur transitoire : `kubectl describe pod` (section `Events`) explique précisément pourquoi chaque nœud a été écarté — un réflexe de diagnostic à connaître, quelle que soit la cause du blocage (anti-affinity, ressources insuffisantes, taints...).

## Pour aller plus loin

- Affinity and anti-affinity : https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity
