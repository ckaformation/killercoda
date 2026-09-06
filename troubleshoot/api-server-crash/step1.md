# Étape 1 — Panne de l'apiserver : le tour des outils

## 1. Sauvegarde le manifest

```
cp /etc/kubernetes/manifests/kube-apiserver.yaml /root/kube-apiserver-backup.yaml
```{{exec}}

## 2. Injecte un faux argument

```
sed -i '/^\s*- kube-apiserver$/a\    - --use-the-force=true' /etc/kubernetes/manifests/kube-apiserver.yaml
```{{exec}}

Laisse quelques secondes à kubelet pour détecter le changement et
tenter de redémarrer le conteneur : le temps de lire la suite.

## 3. Fais le tour des outils

Fais le tour des sources d'information suivantes pour observer ce que
cette panne génère :

- `/var/log/pods/`
- `/var/log/containers/`
- `crictl ps` / `crictl ps -a` / `crictl logs`
- `journalctl -u kubelet`

### /var/log/pods

```
ls /var/log/pods
```{{exec}}

Repère le dossier correspondant au pod `kube-apiserver`, puis regarde
son contenu et ses logs.

### /var/log/containers

```
ls /var/log/containers
```{{exec}}

Ce sont des liens symboliques vers les mêmes fichiers que ci-dessus,
mais nommés différemment (`<pod>_<namespace>_<conteneur>-<id>.log`).

### crictl

`crictl ps` ne montre que les conteneurs en cours d'exécution. Pour
voir aussi ceux qui ont crashé :

```
crictl ps -a
```{{exec}}

Repère l'ID du conteneur `kube-apiserver` dans le résultat
ci-dessus, puis regarde ses logs (remplace `<id-du-conteneur>` par la
valeur trouvée) :

```
crictl logs <id-du-conteneur>
```

### journalctl

```
journalctl -u kubelet --no-pager | tail -100
```{{exec}}

Prends le temps de comparer ce que chaque source montre — elles ne
disent pas exactement la même chose.

## 4. Restaure le manifest

Une fois le tour terminé, restaure le manifest d'origine :

```
cp /root/kube-apiserver-backup.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
```{{exec}}

Observe le conteneur revenir :

```
watch crictl ps
```{{exec}}

(Ctrl+C pour sortir du `watch` une fois `kube-apiserver` visible et
stable.)
