# Bravo !

Tu viens d'explorer les taints et tolerations à travers deux effets bien distincts :

1. **Taint `NoSchedule`** : bloque les nouveaux placements, sans toucher aux pods déjà en place.
2. **Toleration `NoSchedule`** : ajoutée à `millennium-falcon` seul, elle lui permet de revenir sur `controlplane` ; `x-wing-squadron`, non modifié, reste sur `node01`.
3. **Taint `NoExecute`** : contrairement à `NoSchedule`, il **évince activement** les pods déjà en place s'ils ne le tolèrent pas — y compris des pods qui toléraient déjà un autre taint sur ce même nœud.
4. **Toleration `NoExecute`** : une seconde toleration, distincte de la première, nécessaire pour revenir sur `controlplane` malgré ce nouveau taint.

## Points clés à retenir

- Un nœud peut porter **plusieurs taints simultanément** (clés différentes) : un pod doit tolérer **chacun** d'entre eux pour s'y poser sans restriction, une toleration ne "couvre" qu'un seul taint (même clé, même valeur, même effet).
- `NoSchedule` et `NoExecute` sont deux effets bien distincts, pas deux niveaux d'un même mécanisme : le premier n'agit qu'à la création du pod, le second agit en continu, y compris sur des pods déjà en place.
- Comme pour `nodeSelector`, un taint est réévalué au moment du scheduling — un `rollout restart` reste nécessaire pour forcer une réévaluation immédiate quand ce n'est pas automatique (`NoSchedule`, qui n'évince rien de lui-même).

## Pour aller plus loin

- Taints and Tolerations : https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
