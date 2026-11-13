# Bravo !

Tu as parcouru le cycle de vie complet d'une image de conteneur :

1. **Build** : un `Dockerfile` décrit l'image, `docker build -t holocron:v1 .` la fabrique.
2. **Run** : `docker run` crée un conteneur à partir de l'image ; `docker ps` n'affiche que les conteneurs en cours d'exécution, `docker ps -a` affiche aussi ceux qui sont terminés.
3. **Registre local** : en nommant l'image `localhost:5000/holocron:v1` (`docker tag`), tu as pu l'envoyer (`docker push`) dans un registre, la supprimer de la machine, puis la retélécharger automatiquement avec `docker run`.
4. **Registre public** : sans adresse de registre dans le nom, Docker interroge Docker Hub (`nginx:alpine` équivaut à `docker.io/library/nginx:alpine`).

## Ce qu'il faut retenir

- Le nom d'une image suit le format `[registre[:port]/]dépôt[:tag]`.
- Un conteneur vit aussi longtemps que son processus principal.
- Un registre n'est qu'un serveur qui stocke des images ; `docker tag` ajoute un nom, il ne copie rien.

## Lien avec Kubernetes

Le champ `image:` d'un Pod utilise exactement la même syntaxe de nom : `nginx:alpine` est tiré de Docker Hub, `monregistre:5000/holocron:v1` d'un registre précis. Depuis Kubernetes 1.24, Docker n'est plus utilisé comme runtime de conteneurs par Kubernetes (le support intégré, `dockershim`, a été retiré), mais les images construites avec Docker restent utilisables dans un cluster.

## Pour aller plus loin

- Référence du Dockerfile : https://docs.docker.com/engine/reference/builder/
