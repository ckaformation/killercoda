# Étape 2 — Toujours en Pending

Malgré la toleration ajoutée, le pod reste `Pending`. Investigue
pourquoi.

<details>
<summary>💡 Indice</summary>

```
kubectl describe pod clone-vat-0 -n kamino
```{{exec}}

Regarde à nouveau les `Events`, puis compare avec le
`PersistentVolume` associé au PVC du StatefulSet :

```
kubectl get pvc -n kamino
kubectl get pv -o yaml
```{{exec}}

Un `PersistentVolume` peut porter ses propres contraintes de
placement, indépendamment des `tolerations` du pod.

</details>

<details>
<summary>✅ Solution</summary>

`local-path-provisioner` crée chaque `PersistentVolume` avec un
`nodeAffinity` figé sur le nœud où il a été provisionné — ici,
`node01`, puisque c'est là que tournait le pod au moment de la
création du volume. Même planifiable sur `controlplane` grâce à la
toleration, le pod ne peut pas s'y exécuter : le volume, lui, reste
irrémédiablement rattaché à `node01`.

Il n'y a pas de correction en place : il faut recréer le volume. Comme
`node01` est toujours indisponible (maintenance en cours), la
recréation aura lieu sur `controlplane`, seul nœud disponible.

```
kubectl scale statefulset clone-vat -n kamino --replicas=0
```{{exec}}

Supprime le PVC existant (retrouve son nom avec `kubectl get pvc -n
kamino`, généralement `data-clone-vat-0`) :

```
kubectl delete pvc data-clone-vat-0 -n kamino
```{{exec}}

Vérifie que le PV associé a bien été supprimé automatiquement
(`reclaimPolicy: Delete` sur la StorageClass `local-path`) :

```
kubectl get pv
```{{exec}}

Remonte le StatefulSet à 1 réplique : cela déclenche la création d'un
nouveau PVC, donc d'un nouveau PV — cette fois sur `controlplane`,
seul nœud disponible.

```
kubectl scale statefulset clone-vat -n kamino --replicas=1
kubectl get pods -n kamino -o wide
```{{exec}}

Le pod doit finir `Running` sur `controlplane`.

</details>
