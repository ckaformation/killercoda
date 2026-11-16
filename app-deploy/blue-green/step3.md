# Étape 3 — Tester green en interne avec un Service ClusterIP

Avant de rebasculer le trafic public, l'équipe veut tester green depuis l'intérieur du cluster, sans l'exposer à l'extérieur et sans toucher au Service `lightsaber`.

## 1. Créer un Service ClusterIP pour green

`kubectl expose deployment lightsaber-green --port=80`{{exec}}

`kubectl expose` crée un Service du même nom que le Deployment (`lightsaber-green`), recopie son selector (`app=lightsaber,version=green`) et, sans option `--type`, crée un Service de type `ClusterIP`.

`kubectl get svc -o wide`{{exec}}

Compare les deux Services :

- `lightsaber` : type `NodePort`, `PORT(S)` à `80:30080/TCP`, joignable depuis l'extérieur par le nœud ;
- `lightsaber-green` : type `ClusterIP`, `PORT(S)` à `80/TCP`, joignable uniquement depuis le cluster.

`kubectl get endpointslices -l kubernetes.io/service-name=lightsaber-green`{{exec}}

Les endpoints sont les IP des pods green.

## 2. Tester green depuis un pod temporaire

`kubectl run probe-droid --image=busybox:1.36 --rm -it --restart=Never -- wget -qO- http://lightsaber-green`{{exec}}

Réponse attendue : `Sabre laser - version green`, puis `pod "probe-droid" deleted`.

- Le nom court `lightsaber-green` est résolu par le DNS du cluster, car le pod et le Service sont dans le même namespace. Le nom complet est `lightsaber-green.default.svc.cluster.local`.
- `--rm` supprime le pod dès que la commande est terminée.

## 3. Vérifier que le trafic public reste sur blue

`curl http://jedi-temple:30080`{{exec}}

Réponse attendue : `Sabre laser - version blue`. Les deux Services coexistent : les utilisateurs restent sur blue pendant que l'équipe teste green en interne.
