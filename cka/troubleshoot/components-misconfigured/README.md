# Scénario Killercoda — Troubleshooting control plane (kube-controller-manager & kubelet)

## Contenu

```
control-plane-troubleshoot/
├── index.json
├── intro.md
├── intro-background.sh   # crictl + flag bidon (controller-manager) + 2 erreurs kubelet (node01, via SSH)
├── step1.md / step1-verify.sh   # kube-controller-manager (1 indice + 1 solution)
└── step2.md / step2-verify.sh   # kubelet/node01 (1 indice + 1 solution)
└── finish.md
```

## ⚠️ Hypothèse critique à vérifier en priorité

**`intro-background.sh` s'exécute sur `controlplane`, mais doit
modifier des fichiers sur `node01`.** J'utilise `ssh node01` /
`scp ... node01:...` en supposant un accès SSH root sans mot de passe
déjà configuré entre les deux nœuds — convention courante sur les
clusters kubeadm à 2 nœuds de ce type de plateforme, mais **je n'ai
aucune confirmation directe pour ce backend Killercoda précis**. Si
l'injection des erreurs échoue silencieusement, c'est le premier
endroit à vérifier (`ssh node01 echo test` en début de script, par
exemple, pour confirmer la connectivité avant d'aller plus loin).

## Choix effectués et pourquoi

- **`crictl` réinstallé** (`v1.36.0`, même version que les scénarios
  précédents) : aucune confirmation que ce backend 2 nœuds l'a
  préinstallé (contrairement à `local-path-provisioner`, qui lui est
  confirmé préinstallé sur ce backend) — installé par sécurité.
- **Pas de sauvegarde/restauration pour `kube-controller-manager`** :
  contrairement au tout premier scénario apiserver, la demande ne
  mentionne pas de backup ici — la correction se fait en éditant
  directement le manifest pour retirer le flag en trop.
- **Le flag bidon ne casse pas la syntaxe YAML** (contrairement à
  l'erreur `metadata;` d'un scénario précédent) : `kube-controller-
  manager.yaml` reste un YAML valide, donc pas besoin de la manœuvre
  "retirer puis remettre le fichier" pour forcer kubelet à agir —
  une simple édition en place suffit, kubelet remplace normalement le
  pod avec la nouvelle définition (qui échoue ensuite au niveau du
  process, pas du parsing).
- **`step2-verify.sh` vérifie `node01` via `kubectl get node`
  (depuis controlplane)**, pas via SSH : le statut `Ready` du nœud
  reflète fidèlement la santé réelle de son kubelet à travers l'API
  server, sans dépendre à nouveau de SSH pour la vérification —
  seule l'injection initiale des erreurs en a besoin.
- **Cascade d'erreurs pour kubelet/node01** (flag bidon d'abord,
  `apiVersion` commenté ensuite) : le flag inconnu fait échouer le
  parsing de la ligne de commande de kubelet avant même qu'il ne lise
  `config.yaml` — la seconde erreur ne devient donc visible qu'une
  fois la première corrigée. Même logique que la cascade du scénario
  apiserver à 3 erreurs.
- **Commandes côté `node01` non taguées `{{exec}}`** dans `step2.md` :
  je n'ai pas de confirmation que `{{exec}}` cible le bon terminal sur
  un backend multi-nœuds — préféré une instruction en prose ("sur
  node01...") plutôt que de risquer une exécution sur le mauvais nœud.
- **`vim` plutôt que `sed`** pour les corrections manuelles côté
  élève, cohérent avec la préférence déjà exprimée sur les scénarios
  apiserver.
- **`wait-for-ready.sh` retiré entièrement** (script et lancement),
  à la demande de Pierrot : l'étape 1 démarre directement sans étape
  de synchronisation.

## Sources utilisées

- Structure de `/var/lib/kubelet/kubeadm-flags.env` (variable
  `KUBELET_KUBEADM_ARGS`) et de `/var/lib/kubelet/config.yaml`
  (`KubeletConfiguration`) : connaissance générale kubeadm, non
  re-vérifiée par recherche dédiée dans cette conversation.
- Comportement de parsing des flags (échec avant lecture du fichier
  `--config`) : déduit du fonctionnement standard des bibliothèques
  de ligne de commande Go (pflag/cobra), non re-vérifié spécifiquement
  pour `kubelet`.

## Limites connues / hypothèses non vérifiées en conditions réelles

- **L'accès SSH controlplane → node01** (voir plus haut) — le point
  le plus important à valider.
- **Testé uniquement "sur le papier"**, comme les scénarios
  précédents.
- **Format exact de `kubeadm-flags.env`** (une seule ligne se
  terminant par une paire de guillemets) : le `sed` d'injection
  suppose ce format standard kubeadm ; s'il diffère sur cette image,
  l'injection pourrait échouer silencieusement.
- **Nom exact de la ligne `apiVersion` dans `config.yaml`** (`sed`
  cible `^apiVersion:` en tout début de ligne, sans indentation) : à
  confirmer sur le fichier réel généré par cette version de kubeadm.
