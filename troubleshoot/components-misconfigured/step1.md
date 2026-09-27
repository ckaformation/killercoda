# Étape 1 — kube-controller-manager ne redémarre pas

## 0. Vérifier que l'environnement est prêt

```
./wait-for-ready.sh
```{{exec}}

## 1. Diagnostiquer

Le manifest de `kube-controller-manager` vient d'être mis à jour,
mais le composant ne redémarre pas. Corrige le problème.

<details>
<summary>💡 Indice</summary>

Même méthode que pour l'apiserver : `crictl ps -a`, `crictl logs`,
`journalctl -u kubelet`.

</details>

<details>
<summary>✅ Solution</summary>

```
crictl ps -a
```{{exec}}

Repère l'ID du conteneur `kube-controller-manager`, puis regarde ses
logs (remplace `<id-du-conteneur>`) :

```
crictl logs <id-du-conteneur>
```

Un flag inconnu (`--use-the-force=true`) a été ajouté au manifest.
Retire-le :

```
vim /etc/kubernetes/manifests/kube-controller-manager.yaml
```{{exec}}

Enregistre et quitte (`:wq`), puis vérifie :

```
watch crictl ps
```{{exec}}

(Ctrl+C une fois `kube-controller-manager` stable.)

</details>
