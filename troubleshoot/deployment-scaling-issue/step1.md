# Étape 1 — Créer le HPA

## 0. Vérifier que l'environnement est prêt

```
kubectl wait --for=condition=Ready pod -l app=millennium-falcon -n kessel-run --timeout=120s
```{{exec}}

```
kubectl wait --for=condition=Ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s
```{{exec}}

## 1. Créer le HPA

Crée un `HorizontalPodAutoscaler` pour le déploiement
`millennium-falcon` (namespace `kessel-run`) :

- entre 10 et 20 replicas
- basé sur une utilisation CPU moyenne cible de 60 %

<details>
<summary>💡 Indice</summary>

Il est possible d'utiliser `kubectl autoscale`.

</details>

<details>
<summary>✅ Solution</summary>

```
kubectl autoscale deployment millennium-falcon -n kessel-run --min=10 --max=20 --cpu-percent=60
```{{exec}}

</details>

Vérifie :

```
kubectl get hpa -n kessel-run
```{{exec}}
