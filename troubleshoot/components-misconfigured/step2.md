# Étape 2 — kubelet en échec sur node01

Le kubelet ne démarre pas sur `node01`. Connecte-toi à ce nœud et
investigue pourquoi.

<details>
<summary>💡 Indice</summary>

Sur `node01` :

```
journalctl -u kubelet -xe --no-pager | tail -50
```

</details>

<details>
<summary>✅ Solution</summary>

Ces 2 erreurs se révèlent probablement l'une après l'autre : la
première empêche même le process kubelet de démarrer, ce qui masque
la seconde jusqu'à ce qu'elle soit corrigée.

**Erreur 1 — flag de démarrage invalide dans `kubeadm-flags.env`**

Sur `node01` :

```
vim /var/lib/kubelet/kubeadm-flags.env
```

Retire ` --use-the-force=true` ajouté à la fin de la variable
`KUBELET_KUBEADM_ARGS`, enregistre et quitte (`:wq`).

```
systemctl restart kubelet
```

**Erreur 2 — `apiVersion` commenté dans `config.yaml`**

```
vim /var/lib/kubelet/config.yaml
```

Décommente la ligne `apiVersion: kubelet.config.k8s.io/v1beta1` (le
`#` en trop en tout début de ligne), enregistre et quitte (`:wq`).

```
systemctl restart kubelet
```

Vérifie, toujours sur `node01` :

```
systemctl status kubelet
```

Puis, depuis `controlplane` :

```
kubectl get nodes
```{{exec}}

`node01` doit repasser à `Ready`.

</details>
