# Étape 1 — Maintenance de node01

## 1. Préparer node01 pour une maintenance

Le pod du StatefulSet `clone-vat` tourne actuellement sur `node01`.
Une opération de maintenance est prévue sur ce nœud : mets-le hors
service proprement.

```
kubectl cordon node01
kubectl drain node01 --ignore-daemonsets --delete-emptydir-data
```{{exec}}

## 2. Observe la conséquence

```
kubectl get pods -n kamino -o wide
```{{exec}}

Le pod est maintenant `Pending`. Investigue pourquoi, et corrige la
situation pour qu'il puisse à nouveau tourner — sur l'autre nœud
disponible du cluster. Aucune autre indication ici.

<details>
<summary>💡 Indice 1</summary>

```
kubectl describe pod clone-vat-0 -n kamino
```{{exec}}

Regarde la section `Events`, tout en bas.

</details>

<details>
<summary>💡 Indice 2</summary>

```
kubectl describe node controlplane
```{{exec}}

Regarde la section `Taints`. Un pod ne peut être planifié sur un nœud
taint que s'il déclare une `toleration` correspondante.

</details>

<details>
<summary>✅ Solution</summary>

`node01` est cordon/drain, donc plus disponible. Le seul autre nœud du
cluster, `controlplane`, porte le taint
`node-role.kubernetes.io/control-plane:NoSchedule` — posé par défaut
sur les nœuds control-plane pour empêcher d'y planifier des charges de
travail ordinaires. Le pod `clone-vat-0` ne déclare aucune toleration
pour ce taint : il ne peut donc être planifié nulle part.

Ajoute une toleration au StatefulSet pour ce taint :

```
kubectl edit statefulset clone-vat -n kamino
```{{exec}}

Sous `spec.template.spec`, ajoute :

```yaml
tolerations:
- key: node-role.kubernetes.io/control-plane
  operator: Exists
  effect: NoSchedule
```

Le pod existant ne reprend pas automatiquement ce changement de
template : supprime-le pour forcer sa recréation avec la nouvelle
définition.

```
kubectl delete pod clone-vat-0 -n kamino
kubectl get pods -n kamino -o wide
```{{exec}}

Tu devrais voir le pod tenter de se replanifier sur `controlplane` —
mais rester en `Pending`. C'est normal, et c'est l'objet de l'étape
suivante.

</details>
