# Étape 1 — Récupérer les logs

## 0. Vérifier que l'environnement est prêt

```
./wait-for-ready.sh
```{{exec}}

## 1. Extraire les logs

Le pod du déploiement `twin-suns` (namespace `tatooine`) fait tourner
2 conteneurs. Extrais les logs de **tous les conteneurs** de ce pod
dans un seul fichier : `/root/logs.log`.

<details>
<summary>💡 Indice</summary>

La commande `kubectl logs` permet de récupérer les logs d'un pod.

</details>

<details>
<summary>✅ Solution</summary>

```
kubectl logs deployment/twin-suns -n tatooine --all-containers=true --prefix=true > /root/logs.log
```{{exec}}

Vérifie le résultat :

```
cat /root/logs.log
```{{exec}}

</details>
