# Étape 3 — Publier l'image dans un registre local

Un **registre** (*registry*) est un serveur qui stocke et distribue des images. Docker Hub est un registre public ; tu peux aussi héberger le tien. Ici, le registre local est lui-même un conteneur.

## 1. Démarrer un registre local

`docker run -d -p 5000:5000 --name registry registry:2`{{exec}}

`-p 5000:5000` publie le port 5000 du conteneur sur le port 5000 de la machine.

`docker ps`{{exec}}

## 2. Nommer l'image pour ce registre

Le nom complet d'une image a la forme `[registre[:port]/]dépôt[:tag]`. Pour qu'une image soit envoyée vers un registre précis, **son nom doit commencer par l'adresse de ce registre**.

Crée un second nom pour ton image, qui pointe vers le registre local (`localhost:5000`) en gardant le dépôt `holocron` et le tag `v1`. Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` avant de l'exécuter) :

```
docker tag holocron:v1 <A_COMPLETER>
```

<details>
<summary>Solution</summary>

`docker tag holocron:v1 localhost:5000/holocron:v1`{{exec}}

</details>

`docker images`{{exec}}

Tu vois maintenant deux noms avec le **même** identifiant d'image (colonne `IMAGE ID` ou `ID`, selon la version de Docker) : `docker tag` ne copie rien, il ajoute simplement une étiquette.

## 3. Envoyer l'image dans le registre

Complète la commande suivante, en utilisant le nom que tu viens de créer :

```
docker push <A_COMPLETER>
```

<details>
<summary>Solution</summary>

`docker push localhost:5000/holocron:v1`{{exec}}

</details>

## 4. Interroger le registre

Un registre expose une API HTTP. Demande-lui la liste de ses dépôts, puis les tags du dépôt `holocron` :

`curl -s localhost:5000/v2/_catalog`{{exec}}

`curl -s localhost:5000/v2/holocron/tags/list`{{exec}}

## 5. Supprimer l'image en local

Pour prouver que l'image vient bien du registre, elle ne doit plus exister sur la machine. Docker refuse de supprimer une image utilisée par un conteneur, même arrêté : supprime d'abord les conteneurs issus de `holocron:v1`.

`docker ps -aq --filter ancestor=holocron:v1 | xargs -r docker rm -f`{{exec}}

Puis supprime les deux noms de l'image (le dernier nom supprimé efface réellement l'image) :

`docker rmi holocron:v1 localhost:5000/holocron:v1`{{exec}}

`docker images`{{exec}}

L'image `holocron` n'apparaît plus. Le registre, lui, la conserve toujours.

## 6. Lancer un conteneur depuis le registre

Complète la commande suivante, **sans** `--rm` : utilise le nom complet, adresse du registre comprise.

```
docker run <A_COMPLETER>
```

<details>
<summary>Solution</summary>

`docker run localhost:5000/holocron:v1`{{exec}}

</details>

Observe la sortie : Docker annonce qu'il ne trouve pas l'image localement (`Unable to find image ... locally`), la télécharge depuis `localhost:5000`, puis exécute le conteneur, qui affiche ton message.

`docker ps -a`{{exec}}

La colonne `IMAGE` de ton nouveau conteneur indique le nom complet, adresse du registre comprise.
