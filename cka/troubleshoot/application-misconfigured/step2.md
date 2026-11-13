# Étape 2 — outer-rim

Le déploiement `long-range-probe` (namespace `outer-rim`) ne
fonctionne pas correctement. Diagnostique et corrige le problème.

```
kubectl get pods -n outer-rim -o wide
```{{exec}}

<details>
<summary>💡 Indice</summary>

Regarde comment le pod a été planifié — ou plutôt, s'il l'a été.

</details>

<details>
<summary>✅ Solution</summary>

```
kubectl describe pod -n outer-rim -l app=long-range-probe
```{{exec}}

Le pod ne montre aucun événement de planification : le champ
`nodeName` du déploiement pointe directement vers un nœud qui
n'existe pas (`probe-station-7`), ce qui court-circuite le
scheduler.

```
kubectl edit deployment long-range-probe -n outer-rim
```{{exec}}

Retire la ligne `nodeName: probe-station-7`, enregistre et quitte
(`:wq`). Vérifie :

```
kubectl get pods -n outer-rim -o wide
```{{exec}}

</details>
