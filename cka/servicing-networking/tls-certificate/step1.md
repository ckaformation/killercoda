# Étape 1 — Générer le certificat et créer le Secret TLS

## 1. Vérifier que l'environnement est prêt

```
./wait-for-prep.sh
```{{exec}}

## 2. Constater le problème

```
kubectl get pods -n outer-rim
kubectl describe pod -n outer-rim -l app=hologram
```{{exec}}

Le pod reste bloqué : il référence un `Secret` de type `tls` qui
n'existe pas encore (`hologram-tls`).

## 3. Générer le certificat

Génère un certificat auto-signé avec `openssl`. Les options
(algorithme, taille de clé, durée de validité...) sont libres, à une
exception près : le **CN doit correspondre à `hologram.local`**
(`<nom du service>.local`), car c'est ce nom que le serveur nginx
attend (`server_name` dans sa config).

Exemple :

```
openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=hologram.local"
```{{exec}}

## 4. Créer le Secret TLS

Le nom du secret doit correspondre à celui référencé dans le
`Deployment` : **`hologram-tls`**.

```
kubectl create secret tls hologram-tls \
  --cert=tls.crt --key=tls.key \
  -n outer-rim
```{{exec}}

## 5. Relancer le pod

Le pod bloqué ne repart pas tout seul immédiatement : supprime-le pour
qu'il reparte avec le Secret désormais disponible.

```
kubectl delete pod -n outer-rim -l app=hologram
kubectl get pods -n outer-rim -w
```{{exec}}

Le nouveau pod doit passer en `Running` / `1/1 Ready`.
