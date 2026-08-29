# Étape 2 — Autoriser luke vers obi-wan (intra-namespace)

## 1. Écrire la NetworkPolicy d'autorisation

Cette policy cible `obi-wan` (le `podSelector` de la policy désigne le pod qui **reçoit** le trafic) et n'autorise que ce qui vient de `luke` :

`vi /root/allow-luke-to-obiwan.yaml`{{exec}}

Contenu à saisir :

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-luke-to-obiwan
  namespace: tatooine
spec:
  podSelector:
    matchLabels:
      app: obi-wan
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: luke
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

Un `podSelector` dans `from`, sans `namespaceSelector` à côté, cible uniquement les pods du **même namespace** que la `NetworkPolicy` elle-même — ici, `tatooine`.

## 2. Appliquer

`kubectl apply -f /root/allow-luke-to-obiwan.yaml`{{exec}}

## 3. Retester

`OBIWAN_IP=$(kubectl get pod obi-wan -n tatooine -o jsonpath='{.status.podIP}') && kubectl exec luke -n tatooine -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$OBIWAN_IP"`{{exec}}

Cette fois, tu dois obtenir `200` : le deny par défaut est toujours actif pour tout le reste, mais `luke` a maintenant une exception explicite.
