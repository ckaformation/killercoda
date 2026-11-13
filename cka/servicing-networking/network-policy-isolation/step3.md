# Étape 3 — Autoriser luke vers leia (inter-namespaces)

## ⚠️ Le piège classique : AND ou OR ?

Pour autoriser un pod précis, dans un namespace précis, il faut combiner `namespaceSelector` **et** `podSelector`. La façon dont on les indente en YAML change complètement le sens :

**Combinés dans le même élément de liste (ET)** — ce qu'on veut :
```yaml
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: tatooine
        podSelector:
          matchLabels:
            app: luke
```

**Deux éléments séparés de la liste (OU)** — un piège fréquent :
```yaml
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: tatooine
      - podSelector:
          matchLabels:
            app: luke
```

Dans la seconde version, la policy autoriserait **n'importe quel pod du namespace `tatooine`** (donc `obi-wan` aussi) **OU n'importe quel pod nommé `luke` dans n'importe quel namespace** — bien plus large que voulu. La différence tient à un seul niveau d'indentation : un tiret (`-`) de plus ou de moins.

## 1. Écrire la bonne version

`vi /root/allow-luke-to-leia.yaml`{{exec}}

Contenu à saisir (remarque : `kubernetes.io/metadata.name` est un label posé automatiquement par Kubernetes sur chaque namespace, avec son propre nom comme valeur — pas besoin de labelliser `tatooine` à la main) :

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-luke-to-leia
  namespace: alderaan
spec:
  podSelector:
    matchLabels:
      app: leia
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: tatooine
          podSelector:
            matchLabels:
              app: luke
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 2. Appliquer

`kubectl apply -f /root/allow-luke-to-leia.yaml`{{exec}}

## 3. Vérifier : luke passe...

`LEIA_IP=$(kubectl get pod leia -n alderaan -o jsonpath='{.status.podIP}') && kubectl exec luke -n tatooine -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$LEIA_IP"`{{exec}}

Tu dois obtenir `200`.

## 4. ...mais pas obi-wan

`LEIA_IP=$(kubectl get pod leia -n alderaan -o jsonpath='{.status.podIP}') && kubectl exec obi-wan -n tatooine -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$LEIA_IP"`{{exec}}

Cette commande doit **échouer** (timeout, pas de code HTTP). Même s'il est aussi dans `tatooine`, `obi-wan` n'a pas le label `app: luke` — la condition ET fait bien la distinction entre les deux pods du namespace, exactement ce que la version OU n'aurait pas su faire.
