# Conteneurs : build, run, registry local et registry publique

Bienvenue ! Avant de manipuler des Pods Kubernetes, il faut comprendre ce qu'ils contiennent : des **conteneurs**, créés à partir d'**images**, elles-mêmes stockées dans des **registres**. Ce scénario parcourt ce cycle de vie complet avec Docker.

## Ce qui est déjà en place

- Une machine Ubuntu avec Docker.
- Le dossier `/root/holocron`, qui contient un fichier `message.txt` : le contenu de l'application que tu vas empaqueter.

## Ce que tu vas faire

1. **Construire** une petite image à partir d'un `Dockerfile`.
2. **Lancer** un conteneur à partir de cette image, et observer la différence entre `docker ps` et `docker ps -a`.
3. **Publier** l'image dans un registre local, puis lancer un conteneur en la tirant depuis ce registre.
4. **Lancer** une image hébergée sur un registre public (Docker Hub), et comprendre comment Docker sait *où* aller chercher une image.

> Certaines commandes contiennent un `<A_COMPLETER>` : ce n'est pas cliquable, c'est à toi de le remplacer par la bonne valeur avant de l'exécuter.

C'est parti !
