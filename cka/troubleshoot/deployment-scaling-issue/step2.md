# Étape 2 — Où sont passés les pods ?

```
kubectl get hpa -n kessel-run
```{{exec}}

```
kubectl get pods -n kessel-run
```{{exec}}

Le HPA affiche un minimum de 10 replicas, pourtant seuls 5 pods
tournent dans le namespace. Investigue pourquoi, et corrige la
situation pour que 20 pods puissent tourner dans `kessel-run`.

<details>
<summary>💡 Indice</summary>

Regarde du côté des quotas appliqués au namespace.

</details>

<details>
<summary>✅ Solution</summary>

Un `ResourceQuota` limite le namespace `kessel-run` à 5 pods maximum
— c'est ce qui empêche le déploiement d'atteindre les 10 replicas
minimum demandés par le HPA.

```
kubectl get resourcequota -n kessel-run
```{{exec}}

```
kubectl describe resourcequota -n kessel-run
```{{exec}}

Édite le quota pour autoriser au moins 20 pods :

```
kubectl edit resourcequota kessel-run-quota -n kessel-run
```{{exec}}

Remplace la valeur de `pods` (actuellement `"5"`) par `"20"` ou plus,
enregistre, puis vérifie :

```
kubectl get pods -n kessel-run
```{{exec}}

Tu dois voir le déploiement remonter progressivement vers 10 pods
(le minimum du HPA).

</details>
