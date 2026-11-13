# Conteneurs : build, run, registry local et registry publique

Scénario Killercoda d'introduction aux conteneurs avec Docker, en 4 étapes :

1. **Construire une image** : Dockerfile (`FROM alpine`, `COPY`, `CMD`) puis `docker build -t holocron:v1 .`.
2. **Lancer un conteneur et lister les conteneurs** : `docker run`, `docker ps` (vide), `docker ps -a` (conteneur `Exited (0)`), puis un second conteneur lancé en arrière-plan avec `sleep 3600`.
3. **Registre local** : `registry:2` sur `localhost:5000`, `docker tag`, `docker push`, interrogation de l'API (`/v2/_catalog`), suppression de l'image en local, puis `docker run localhost:5000/holocron:v1`.
4. **Registre public** : `docker run -d -p 8080:80 --name <nom> nginx:alpine`, `curl`, et comparaison de l'origine des images.

## Fichiers

| Fichier | Rôle |
|---|---|
| `index.json` | Définition du scénario, backend `ubuntu` |
| `intro.md`, `intro-background.sh` | Présentation ; crée `/root/holocron/message.txt` et installe Docker uniquement s'il est absent |
| `step1.md` … `step4.md` | Énoncés (commandes à compléter marquées `<A_COMPLETER>`, non cliquables) |
| `step1-verify.sh` … `step4-verify.sh` | Vérifications de l'état réel (image qui affiche le message, conteneur `Exited (0)` + conteneur `running`, registre qui contient `holocron:v1`, nginx qui répond 200) |
| `finish.md` | Conclusion et lien avec Kubernetes |

## Ce qui a été testé

Avec un vrai daemon Docker (Docker CE 29.9.2) dans mon environnement de travail :

- `intro-background.sh`, étapes 1 et 2 et leurs scripts de vérification (échec avant l'action de l'élève, succès après) ;
- la partie locale de l'étape 3 : `docker tag`, suppression des conteneurs avec `xargs -r`, `docker rmi` des deux noms ;
- les chemins d'échec des vérifications 3 et 4 (message clair, code de sortie 1).

Docker Hub n'est pas joignable depuis mon environnement : la base `alpine` a été simulée par un import local. **Non testés** : le téléchargement de `alpine`, `registry:2` et `nginx:alpine`, le `push` et le `pull` vers `localhost:5000`, l'API du registre, nginx sur le port 8080, et les scripts `step3-verify.sh` et `step4-verify.sh` dans leur cas de succès.

## Hypothèses non confirmées

- **Docker préinstallé sur le backend `ubuntu`** : non confirmé. `intro-background.sh` installe `docker.io` depuis les dépôts Ubuntu s'il est absent. Dans ce cas, l'installation peut ne pas être terminée quand l'élève arrive à l'étape 1 : l'étape 1 commence donc par `docker version` avec une consigne d'attente.
- **Accès Internet vers Docker Hub depuis la VM** : supposé identique aux scénarios Kubernetes (pull de `nginx` déjà fonctionnel). Les pulls anonymes sur Docker Hub peuvent aussi être limités en nombre ; je n'ai pas vérifié si cela peut se produire sur Killercoda.
- **Registre en HTTP sur `localhost:5000`** : le flux (tag `localhost:5000/...`, push, suppression locale, pull) est celui de la documentation Docker sur le déploiement d'un registre, sans configuration de TLS. Non testé ici.
- **`curl` présent et ports `5000` et `8080` libres** sur le backend `ubuntu` : supposé.
- **Blocs `<details>` contenant des `{{exec}}`** (solutions de l'étape 3) : l'affichage des `<details>` est confirmé, pas le fait que les commandes cliquables fonctionnent à l'intérieur.
- **Affichage de `docker images`** : la mise en forme change selon la version de Docker (colonnes `REPOSITORY`/`TAG`/`IMAGE ID` sur les versions plus anciennes, `IMAGE`/`ID` sur Docker 29). Les énoncés citent les deux variantes. Un avertissement « legacy builder » peut aussi apparaître au `docker build` si buildx est absent ; je ne l'ai pas observé.
- **Preuve du pull** : `step3-verify.sh` vérifie que `holocron:v1` n'existe plus, qu'un conteneur a été lancé avec le nom `localhost:5000/holocron:v1` et que le registre contient l'image. Il ne peut pas prouver que le pull a eu lieu (un élève qui garderait le nom `localhost:5000/holocron:v1` en local passerait aussi).
- **Liens** : seul le lien vers la référence du Dockerfile est indiqué dans `finish.md`. Je n'ai pas pu confirmer d'URL officielle pour la documentation du registre, donc je ne l'ai pas citée.
