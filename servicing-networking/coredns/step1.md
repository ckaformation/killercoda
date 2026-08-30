# Étape 1 — Quelque chose ne tourne pas rond

Le cluster a été préparé pour toi, mais quelque chose s'est déréglé.
Aucune autre indication ici : à toi de mener l'investigation avec les
outils habituels.

```
kubectl get pods -A
```{{exec}}

Une fois le ou les composants en cause identifiés, corrige la
situation pour que le cluster retrouve un état sain — un cluster où
plus aucun pod ne devrait redémarrer en boucle.

<details>
<summary>💡 Indice 1</summary>

Regarde du côté des logs des pods qui te semblent instables :

```
kubectl logs -n kube-system -l k8s-app=kube-dns
```{{exec}}

</details>

<details>
<summary>💡 Indice 2</summary>

La configuration de ces pods (le fichier `Corefile`) est stockée dans
un ConfigMap du namespace `kube-system` :

```
kubectl get configmap coredns -n kube-system -o yaml
```{{exec}}

</details>

<details>
<summary>✅ Solution</summary>

Une ligne inconnue (`holocron`) a été insérée dans le `Corefile` du
ConfigMap `coredns`. Ce n'est pas une directive reconnue par CoreDNS :
au démarrage, l'analyse du `Corefile` échoue, le process quitte
immédiatement, et le pod repart donc en `CrashLoopBackOff`.

1. Édite le ConfigMap pour retirer la ligne en trop :

   ```
   kubectl edit configmap coredns -n kube-system
   ```{{exec}}

   Supprime la ligne `holocron` (elle apparaît juste après l'ouverture
   du bloc `.:53 {`), puis enregistre.

2. Force un redémarrage pour appliquer immédiatement la correction,
   plutôt que d'attendre le prochain cycle de `CrashLoopBackOff` :

   ```
   kubectl -n kube-system rollout restart deployment/coredns
   kubectl -n kube-system rollout status deployment/coredns
   ```{{exec}}

</details>
