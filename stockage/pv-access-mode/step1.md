# Étape 1 — Un volume bloqué

Dans le namespace `jedi-archives`, un `PersistentVolumeClaim` reste
bloqué :

```
kubectl get pvc -n jedi-archives
```{{exec}}

Corrige la situation pour que ce PVC passe à l'état `Bound`. Aucune
autre indication ici : à toi d'investiguer.

<details>
<summary>💡 Indice</summary>

Un PVC ne se lie pas tout seul à n'importe quel `PersistentVolume` :
il faut que le PV et le PVC soient compatibles sur plusieurs points
(capacité, `accessModes`, `storageClassName`...). Compare les deux :

```
kubectl get pv
kubectl get pvc -n jedi-archives -o yaml
```{{exec}}

</details>

<details>
<summary>✅ Solution</summary>

Le PV `holocron-pv` est déclaré en `accessModes: [ReadOnlyMany]`,
alors que le PVC `holocron-storage` demande `ReadWriteOnce`. Ces deux
modes ne sont pas compatibles : le PV ne peut pas satisfaire la
demande du PVC, qui reste donc `Pending`.

La correction consiste à modifier le PV pour qu'il supporte
`ReadWriteOnce` (et pas l'inverse : réduire le PVC à `ReadOnlyMany`
le débloquerait aussi, mais ça ne conviendrait pas à PostgreSQL à
l'étape suivante, qui a besoin d'écrire) :

```
kubectl edit pv holocron-pv
```{{exec}}

Remplace `accessModes: [ReadOnlyMany]` par `accessModes:
[ReadWriteOnce]` (ou ajoute `ReadWriteOnce` à la liste), enregistre,
puis vérifie :

```
kubectl get pvc -n jedi-archives
```{{exec}}

Le PVC doit passer à `Bound`.

</details>
