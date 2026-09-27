# Étape 3 — endor

Le déploiement `ewok-patrol` (namespace `endor`) ne fonctionne pas
correctement. Diagnostique et corrige le problème.

```
kubectl get pods -n endor
```{{exec}}

<details>
<summary>💡 Indice</summary>

Regarde les événements au niveau du déploiement lui-même, pas
seulement du pod (`kubectl describe deployment`, `kubectl get
events`).

</details>

<details>
<summary>✅ Solution</summary>

```
kubectl describe deployment ewok-patrol -n endor
```{{exec}}

Le déploiement référence un `ServiceAccount` qui n'existe pas
(`imperial-clearance`), ce qui empêche la création du pod.

```
kubectl edit deployment ewok-patrol -n endor
```{{exec}}

Remplace `serviceAccountName: imperial-clearance` par
`serviceAccountName: default` (ou retire simplement la ligne — le
ServiceAccount `default` existe dans tous les namespaces), enregistre
et quitte (`:wq`). Vérifie :

```
kubectl get pods -n endor
```{{exec}}

</details>
