# Étape 1 — Deny by default dans les deux namespaces

`/root/wait-for-prep.sh`{{exec}}

## 1. Tester la situation actuelle

Rien n'empêche aujourd'hui `luke` de joindre `obi-wan`, dans le même namespace :

`OBIWAN_IP=$(kubectl get pod obi-wan -n tatooine -o jsonpath='{.status.podIP}') && kubectl exec luke -n tatooine -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$OBIWAN_IP"`{{exec}}

Tu devrais obtenir `200`.

## 2. Écrire la NetworkPolicy de deny par défaut

Une `NetworkPolicy` avec un `podSelector` vide s'applique à **tous** les pods du namespace ; sans règle `ingress` définie, aucun trafic entrant n'est autorisé — c'est le pattern officiel de "deny all ingress by default".

`vi /root/deny-tatooine.yaml`{{exec}}

Contenu à saisir :

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: tatooine
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

`kubectl apply -f /root/deny-tatooine.yaml`{{exec}}

## 3. Répéter pour alderaan

`vi /root/deny-alderaan.yaml`{{exec}}

Même contenu, seul le namespace change :

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: alderaan
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

`kubectl apply -f /root/deny-alderaan.yaml`{{exec}}

## 4. Retester

`OBIWAN_IP=$(kubectl get pod obi-wan -n tatooine -o jsonpath='{.status.podIP}') && kubectl exec luke -n tatooine -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$OBIWAN_IP"`{{exec}}

Cette fois, la commande doit **échouer** (timeout, pas de code HTTP) : même en intra-namespace, plus rien ne passe.
