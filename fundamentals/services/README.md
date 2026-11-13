# Scénario Killercoda — Service : pourquoi, ClusterIP, DNS et NodePort

## Contenu

```
service-fundamentals/
├── index.json                   # backend kubernetes-kubeadm-2nodes, 5 étapes
├── intro.md
├── intro-background.sh          # alias k, taint control-plane, Deployment echo-base (3 réplicas)
├── step1.md / step1-verify.sh   # curl sur l'IP d'un pod ; IP éphémère (explication)
├── step2.md / step2-verify.sh   # k expose, k get svc -o wide, curl sur la CLUSTER-IP, selector et labels
├── step3.md / step3-verify.sh   # k delete pod : l'ancienne IP ne répond plus, le Service oui
├── step4.md / step4-verify.sh   # curl depuis un pod : nom court, <svc>.<ns>, FQDN ; laïus sur la nomenclature
├── step5.md / step5-verify.sh   # k edit svc -> NodePort 30080 ; curl sur controlplane et node01
└── finish.md
```

## Choix effectués

- **Image `wbitt/network-multitool`** pour `echo-base`. Je n'ai pas retenu `nginx:alpine` : dans le Dockerfile récent que j'ai pu lire (variante `alpine-slim`, dont `alpine` dérive), `curl` n'est installé que le temps du build puis supprimé, donc l'image finale n'en contient pas. D'après sa page Docker Hub, `wbitt/network-multitool` embarque nginx (port 80), `curl` et des outils réseau. Son exemple de sortie montre une page qui affiche le nom du container et son IP : dans un pod, cela doit permettre de voir quel pod répond.
- **Deployment de 3 réplicas** dans `default` (« 4m3 replica » dans la demande interprété comme 3, d'après la suite : « le deployment a un replica à 3 depuis le début »).
- **Fichier repère `/root/pod-ip.txt`** (ajout par rapport à la demande). L'étape 1 est de l'observation, qu'un script ne peut pas constater. L'élève y enregistre l'IP du pod appelé ; `step1-verify.sh` contrôle que c'est bien l'IP d'un pod de `echo-base` qui répond. À l'étape 3, l'élève supprime ce pod-là : `step3-verify.sh` contrôle que cette IP n'est plus celle d'aucun pod, et le texte montre que l'ancienne IP ne répond plus alors que le Service répond. Cela concrétise l'explication de l'étape 1. Si tu préfères rester plus proche de la demande, ces deux éléments peuvent être retirés sans impact sur les autres étapes.
- **FQDN complet à l'étape 4** : en plus du nom court et de `<svc>.<namespace>`, l'élève appelle le FQDN, après le laïus sur la nomenclature et un coup d'œil à `/etc/resolv.conf` (`nameserver`, `search`, `ndots`).
- **`k describe svc`** plutôt que `k get endpoints` pour montrer les endpoints : l'API Endpoints est dépréciée dans les versions récentes de Kubernetes et affiche un avertissement.
- **Étape 4 : vérification fonctionnelle seulement** : `step4-verify.sh` contrôle que les trois noms répondent depuis un pod, mais ne peut pas prouver que l'élève a lancé les commandes.
- **Taint du `controlplane` (re)posé avec `--overwrite`**, comme dans `pod-fundamentals`, pour que les 3 pods soient sur `node01` et que l'étape 5 puisse montrer un NodePort ouvert sur un node sans pod.
- **Pas de `wait-for-prep.sh`** : l'étape 1 commence par `k rollout status deploy echo-base`, avec une consigne d'attente.

## Tested on paper only — hypothèses à vérifier au premier passage

Je n'ai pas pu exécuter ce scénario contre un cluster. Ce qui a été testé : la syntaxe de tous les scripts (`bash -n`) et la logique des cinq scripts de vérification, avec de faux `kubectl` et `curl` (succès et chacun des échecs). Ce qui reste à vérifier :

- **Image `wbitt/network-multitool`** : tag `latest` non épinglé (son contenu peut évoluer). Le contenu de la page d'accueil (nom du container, IP) vient de l'exemple de sa page Docker Hub ; que le nom affiché soit celui du pod est une déduction de ma part (le hostname d'un pod est son nom par défaut).
- **Joignabilité depuis `controlplane`** : j'ai supposé que `curl` depuis le `controlplane` atteint l'IP d'un pod situé sur `node01` (étape 1) et la `CLUSTER-IP` (étape 2). Non vérifié sur ce backend (Cilium).
- **NodePort sur l'IP interne des deux nodes** : supposé fonctionnel. Dans le scénario `kubeadm-from-scratch` (Calico, installé à la main), `localhost:<NodePort>` depuis `controlplane` avait été refusé, sans cause identifiée. Ici, les appels se font sur les `INTERNAL-IP` des nodes, pas sur `localhost`.
- **Ancienne IP après suppression du pod** : l'étape 3 affirme que `curl` sur l'ancienne IP échoue. Je pars du principe que le nouveau pod reçoit une autre adresse ; une réutilisation de la même adresse est improbable mais je ne peux pas l'exclure. Dans ce cas, `step3-verify.sh` échouerait aussi.
- **Répartition des appels (étape 2)** : l'énoncé annonce plusieurs noms de pods sur 10 appels ; la répartition n'étant pas garantie régulière, une exécution malchanceuse pourrait n'en montrer qu'un ou deux.
- **DNS** : contenu de `/etc/resolv.conf` (`nameserver` = `CLUSTER-IP` de `kube-dns`, liste `search`, `ndots:5`), domaine `cluster.local` et Service `kube-dns` dans `kube-system` : comportement standard d'un cluster kubeadm, mais non constaté sur ce backend.
- **Syntaxes `kubectl`** : `k expose deployment ... --port=80` (nom du Service identique, selector recopié), colonnes de `k get svc -o wide`, `k exec deploy/echo-base -- curl ...`, ligne `Endpoints` de `k describe svc`, et l'édition `k edit svc` vers `NodePort` avec `nodePort: 30080`, sont écrites de mémoire et non exécutées.
- **Accès à Docker Hub** depuis `node01` pour `wbitt/network-multitool`, comme dans les scénarios précédents.
- **Liens du `finish.md`** : URL canoniques de la documentation Kubernetes, non vérifiées par un fetch.
