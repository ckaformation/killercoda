# Étape 2 — Restreindre les versions TLS acceptées

La config nginx actuelle accepte TLS 1.2 **et** 1.3 :

```
ssl_protocols TLSv1.2 TLSv1.3;
```

## 1. Modifier le ConfigMap

Édite le ConfigMap pour n'accepter **que** TLS 1.3 :

```
kubectl edit configmap hologram-nginx-conf -n outer-rim
```{{exec}}

Remplace la ligne par :

```
ssl_protocols TLSv1.3;
```

## 2. Relancer le pod

Un changement de ConfigMap ne se propage pas immédiatement dans le
pod déjà démarré. Force le redémarrage :

```
kubectl delete pod -n outer-rim -l app=hologram
kubectl -n outer-rim rollout status deployment/hologram
```{{exec}}

## 3. Vérifier avec curl

```
CLUSTER_IP=$(kubectl get svc hologram -n outer-rim -o jsonpath='{.spec.clusterIP}')
```{{exec}}

Test en TLS 1.3 (doit réussir) :

```
curl --tlsv1.3 --cacert tls.crt --resolve hologram.local:443:$CLUSTER_IP https://hologram.local/
```{{exec}}

Test en TLS 1.2 (doit échouer) :

```
curl --tlsv1.2 --tls-max 1.2 --cacert tls.crt --resolve hologram.local:443:$CLUSTER_IP https://hologram.local/
```{{exec}}

> ⚠️ `--tlsv1.2` seul ne force **pas** exactement TLS 1.2 : c'est un
> minimum ("TLS 1.2 ou plus récent"), pas une version figée. Sans
> `--tls-max 1.2`, curl pourrait très bien négocier du TLS 1.3 et le
> test réussirait quand même, ce qui ne prouverait rien. `--tls-max
> 1.2` plafonne réellement la version utilisée à 1.2.

La première commande doit répondre avec le texte du serveur. La
seconde doit échouer avec une erreur de négociation TLS
(`SSL_ERROR_SYSCALL`, `alert protocol version`, ou équivalent selon
la bibliothèque TLS utilisée par `curl`).
