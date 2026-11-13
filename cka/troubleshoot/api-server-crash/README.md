# Scénario Killercoda — Troubleshooting kube-apiserver

## Contenu

```
apiserver-troubleshoot/
├── index.json          # pas de champ "verify" sur les 3 étapes, comme demandé
├── intro.md
├── intro-background.sh   # backup du manifest + injection du 1er faux argument
├── step1.md   # tour guidé des outils (aucun verify)
├── step2.md   # --etcd-servers erroné, crictl/journalctl uniquement (aucun verify)
├── step3.md   # apiVersion corrompue, sans indication (aucun verify)
└── finish.md
```

## Corrections suite à retour de Pierrot

- **Base de départ saine** : `intro-background.sh` ne casse plus rien
  automatiquement. Il se contente d'installer `crictl` (absent par
  défaut sur ce backend). La sauvegarde du manifest et l'injection du
  premier faux argument sont maintenant des actions explicites de
  l'élève, au tout début de l'étape 1.
- **`crictl` installé en arrière-plan** (absent par défaut sur ce
  backend, contrairement à ce que je supposais initialement) :
  installation par tarball depuis les releases GitHub officielles de
  `kubernetes-sigs/cri-tools` (`v1.36.0`, version demandée par
  Pierrot), avec un `/etc/crictl.yaml` explicite
  pointant vers le socket containerd — évite de dépendre d'une
  auto-détection d'endpoint, dépréciée dans les versions récentes de
  crictl.

## Corrections de typos (silencieuses, vrais chemins Kubernetes)

- `/var/logs/pods` → `/var/log/pods`
- `/var/logs/containers` → `/var/log/containers`

## Choix effectués et pourquoi

- **Aucun `verify` sur les 3 étapes**, conformément à la demande : ce
  scénario casse volontairement `kube-apiserver`, donc `kubectl`
  serait indisponible pendant une bonne partie de l'exercice — un
  script de vérification basé sur `kubectl` (comme tous les
  précédents) ne fonctionnerait pas de façon fiable ici.
- **Faux argument étape 1 : `--use-the-force=true`** (au lieu d'un nom
  quelconque) : petit clin d'œil thématique, sans conséquence
  fonctionnelle — n'importe quel flag inconnu provoque le même effet
  (échec du parsing des arguments par `kube-apiserver`, sortie
  immédiate du process).
- **`--etcd-servers=https://192.0.2.1:2379`** à l'étape 2 :
  `192.0.2.0/24` est une plage réservée à la documentation
  (TEST-NET-1, RFC 5737), garantie non routable — évite de tomber par
  accident sur une IP réellement joignable qui fausserait
  l'observation.
- **`holocron: order66`** à l'étape 3 (remplace `apiVersion: v1`) :
  clé ET valeur non reconnues, cohérent avec la demande ("une clé et
  une valeur bidon"), plutôt que de garder la clé `apiVersion` avec
  juste une valeur invalide.
- **Sauvegarde dans `/root/kube-apiserver-backup.yaml`**, en dehors de
  `/etc/kubernetes/manifests/` : un fichier de sauvegarde laissé DANS
  ce dossier serait lui-même interprété par kubelet comme un second
  pod statique `kube-apiserver`, ce qu'il faut éviter.
- **Édition via `sed` plutôt qu'un éditeur interactif (`vi`/`nano`)**
  pour les 3 modifications : plus fiable dans un terminal web
  Killercoda, reproductible, et compatible avec la consigne "une seule
  commande par bloc `{{exec}}`" déjà donnée sur le scénario précédent
  — que j'ai reconduite ici par cohérence, bien qu'elle n'ait pas été
  répétée explicitement pour ce scénario.
- **`crictl logs <id-du-conteneur>` laissé sans `{{exec}}`** dans les
  3 étapes : ce bloc contient un placeholder à remplacer par l'élève ;
  le marquer `{{exec}}` enverrait le texte littéral (avec les
  chevrons) au terminal.
- **Socket containerd supposé** : `unix:///run/containerd/containerd.sock`
  dans `/etc/crictl.yaml` — chemin standard pour un kubeadm avec
  containerd, mais non re-vérifié spécifiquement sur ce backend
  Killercoda. Si `crictl ps` échoue avec une erreur de connexion, ce
  chemin de socket est le premier point à vérifier
  (`ls /run/containerd/` ou `ls /var/run/containerd/`).

## Sources utilisées

- Comportement des pods statiques (kubelet surveille
  `/etc/kubernetes/manifests/`, redémarre le conteneur au changement
  de fichier, gère le cycle de vie indépendamment de la disponibilité
  de l'apiserver) : connaissance générale Kubernetes, non re-vérifiée
  par recherche dédiée dans cette conversation.
- Comportement des bibliothèques de parsing d'arguments utilisées par
  les composants Kubernetes (flag inconnu ⇒ sortie immédiate en
  erreur) : connaissance générale, non re-vérifiée spécifiquement.
- Chemins `/var/log/pods` et `/var/log/containers`, et rôle de
  `crictl ps` / `crictl ps -a` / `crictl logs` : connaissance générale
  Kubernetes/CRI.

## Limites connues / hypothèses non vérifiées en conditions réelles

- **Testé uniquement "sur le papier"**, comme les scénarios
  précédents — plus encore que d'habitude ici, vu la nature du
  scénario (modification directe de fichiers système, comportement de
  kubelet face à des manifests invalides).
- **Indentation à 4 espaces supposée** pour la liste `command:` du
  manifest `kube-apiserver.yaml` généré par kubeadm (utilisée par le
  `sed` d'injection dans `intro-background.sh`). Très stable d'une
  version de kubeadm à l'autre dans mon expérience, mais non
  re-vérifiée pour la version exacte utilisée par ce backend
  Killercoda — à corriger si l'injection échoue silencieusement (le
  `sed` ne trouverait alors simplement pas la ligne `- kube-apiserver`
  avec cette regex, mais je n'ai pas ajouté de vérification post-
  injection pour le confirmer automatiquement, cohérent avec l'absence
  de `verify` demandée sur ce scénario).
- **Comportement exact de kubelet face à l'étape 3 (`apiVersion`
  corrompue)** : je pars du principe que le fichier devient
  indécodable comme objet `Pod` valide, ce qui devrait empêcher
  kubelet de le traiter comme une mise à jour valable du pod statique
  — mais je n'ai pas de confirmation directe sur l'état exact dans
  lequel se retrouve alors le conteneur `kube-apiserver` déjà en cours
  d'exécution (reste inchangé ? erreur silencieuse côté kubelet
  seulement ?). C'est précisément le genre de nuance que l'étape est
  censée faire découvrir à l'élève par l'observation réelle, donc pas
  bloquant pour l'exercice, mais je ne peux pas te garantir par avance
  quelle source de logs sera la plus parlante pour ce cas précis.
- **Disponibilité de `crictl` déjà configuré** (pointant vers le bon
  socket containerd) sur ce backend : je m'appuie sur le fait que cet
  outil est déjà mentionné comme disponible dans le contexte général
  de ce cursus, sans re-test spécifique dans cette conversation.
