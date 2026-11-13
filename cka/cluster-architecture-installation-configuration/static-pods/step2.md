# Étape 2 — Changer le staticPodPath du kubelet (sur node01)

> Toute cette étape se déroule sur l'onglet **`node01`**, sauf mention contraire.

## Pourquoi node01, et pas controlplane ?

`staticPodPath` est un réglage **global** du kubelet : il ne concerne pas que ton pod `static-web`, mais **tous** les manifestes que ce kubelet surveille. Sur `controlplane`, ce dossier contient aussi `kube-apiserver.yaml`, `etcd.yaml`, `kube-scheduler.yaml` et `kube-controller-manager.yaml` — changer `staticPodPath` là-bas sans précaution, puis redémarrer le kubelet, arrêterait le control-plane entier si ces manifestes ne suivent pas.

Sur `node01`, ce risque n'existe pas : il n'y a que `static-web.yaml`. C'est délibéré, pour pouvoir manipuler ce réglage sans mettre en danger le cluster — mais retiens bien le principe général, qui s'applique à **tout** nœud, y compris control-plane : un manifeste doit se trouver physiquement dans le `staticPodPath` en vigueur pour que le pod correspondant existe.

## 1. Créer le nouveau dossier et y copier le manifeste existant

`mkdir -p /etc/kubernetes/manifests-custom`{{exec}}

`cp /etc/kubernetes/manifests/*.yaml /etc/kubernetes/manifests-custom/`{{exec}}

`ls /etc/kubernetes/manifests-custom`{{exec}}

> On garde volontairement une copie dans l'ancien dossier (`cp`, pas `mv`) : ça donne un filet de rattrapage si jamais quelque chose se passe mal — il suffirait de repointer `staticPodPath` vers l'ancien dossier et de redémarrer le kubelet pour revenir en arrière. Sur un nœud control-plane, cette étape serait **obligatoire** pour tous les manifestes présents, pas optionnelle.

## 2. Modifier la configuration du kubelet

`grep staticPodPath /var/lib/kubelet/config.yaml`{{exec}}

`sed -i 's#^staticPodPath:.*#staticPodPath: /etc/kubernetes/manifests-custom#' /var/lib/kubelet/config.yaml`{{exec}}

`grep staticPodPath /var/lib/kubelet/config.yaml`{{exec}}

## 3. Redémarrer le kubelet

`systemctl restart kubelet`{{exec}}

## 4. Vérifier que tout a survécu

`crictl ps --name web`{{exec}}

Le conteneur `web` doit toujours apparaître.

Bascule sur l'onglet **`controlplane`** :

`k get nodes`{{exec}}

`k get pods -n kube-system -o wide`{{exec}}

`k get pod static-web-node01 -o wide`{{exec}}

Les deux nœuds doivent être `Ready`, les 4 pods du control-plane toujours `Running` dans `kube-system` (ils n'ont pas bougé, on n'a touché qu'à `node01`), et `static-web-node01` toujours `Running` : la relocalisation n'a causé aucune interruption, précisément parce que le manifeste a été copié **avant** le redémarrage du kubelet.
