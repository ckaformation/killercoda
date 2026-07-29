# Étape 4 — Rattacher le nœud worker avec kubeadm join

## 1. Récupérer la commande de jonction

Si tu as encore sous les yeux la sortie de `kubeadm init` (étape 2), la commande `kubeadm join ...` s'y trouve déjà. Sinon, régénère-la depuis l'onglet **`controlplane`** :

`kubeadm token create --print-join-command`{{exec}}

Cette commande affiche une ligne du type :

```
kubeadm join 172.30.1.2:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

Copie cette ligne complète.

## 2. Rejoindre le cluster depuis node01

Bascule sur l'onglet **`node01`**, puis exécute la commande copiée, précédée de `sudo` :

```
sudo kubeadm join 172.30.1.2:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

> Remplace bien `<token>` et `<hash>` par les valeurs affichées chez toi — elles sont propres à ton cluster et changent à chaque exécution.

`kubeadm join` effectue ses propres pre-flight checks, télécharge les informations du cluster, puis configure et démarre le `kubelet` sur ce nœud.

## 3. Vérifier depuis controlplane

Reviens sur l'onglet **`controlplane`** :

`kubectl get nodes`{{exec}}

`node01` doit apparaître, puis passer à l'état `Ready` après quelques secondes (le DaemonSet Calico installé à l'étape 3 s'y déploie automatiquement, sans action supplémentaire de ta part).
