# Étape 3 — Déclencher le HPA

Génère suffisamment de charge CPU sur plusieurs pods du déploiement
`millennium-falcon` pour déclencher le HPA et faire apparaître au
moins un replica supplémentaire.

L'image utilisée est `polinux/stress`, qui embarque l'outil `stress`.
La commande `stress --cpu 1` sature un cœur CPU.

<details>
<summary>💡 Indice</summary>

Tu peux exécuter une commande directement à l'intérieur d'un pod déjà
en cours d'exécution.

</details>

<details>
<summary>✅ Solution</summary>

Récupère les noms de pods :

```
kubectl get pods -n kessel-run
```{{exec}}

Lance `stress --cpu 1` sur 3 pods différents, en arrière-plan
(remplace `<pod-1>`, `<pod-2>`, `<pod-3>` par des noms réels) :

```
kubectl exec -n kessel-run <pod-1> -- stress --cpu 1 &
kubectl exec -n kessel-run <pod-2> -- stress --cpu 1 &
kubectl exec -n kessel-run <pod-3> -- stress --cpu 1 &
```

Dans un nouvel onglet de terminal, observe la charge CPU :

```
kubectl top pod -n kessel-run
```

Dans un autre nouvel onglet, observe le HPA réagir :

```
kubectl get hpa -n kessel-run -w
```

Tu devrais voir apparaître au moins un replica supplémentaire au-delà
du minimum de 10.

</details>
