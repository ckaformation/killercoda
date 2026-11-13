# Étape 2 — --etcd-servers erroné

Modifie le manifest pour donner une valeur erronée à
`--etcd-servers` :

```
sed -i 's#--etcd-servers=.*#--etcd-servers=https://192.0.2.1:2379#' /etc/kubernetes/manifests/kube-apiserver.yaml
```{{exec}}

Cette fois, **n'utilise ni `/var/log/pods` ni `/var/log/containers`** :
observe uniquement avec `crictl` et `journalctl`.

```
crictl ps -a
```{{exec}}

Repère l'ID du conteneur, puis regarde ses logs (remplace
`<id-du-conteneur>`) :

```
crictl logs <id-du-conteneur>
```

Regarde aussi :

```
journalctl -u kubelet | grep apiserver
```{{exec}}

## Restaurer le manifest

```
cp /root/kube-apiserver-backup.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
```{{exec}}

```
watch crictl ps
```{{exec}}
