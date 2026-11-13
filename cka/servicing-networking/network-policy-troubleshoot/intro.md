# Troubleshooting NetworkPolicy

Bienvenue ! Contrairement au scénario précédent (`netpol-isolation`), ici on ne te guide pas commande par commande : deux `NetworkPolicy` sont **déjà en place, mais cassées**. À toi de diagnostiquer pourquoi, et de corriger.

Chaque étape propose :
- un **énoncé** décrivant le comportement attendu (et celui observé) ;
- un bouton **Tip**, si tu veux une piste sans la réponse ;
- un bouton **Solution**, avec la correction complète et son explication.

Essaie de résoudre chaque cas par toi-même avant de dérouler l'un ou l'autre.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud, CNI Cilium (supporte les `NetworkPolicy`).
- Quatre namespaces : **dagobah**, **endor**, **kamino**, **mustafar**.
- Dans **dagobah** : le pod `han`. Dans **endor** : le pod `chewie`. Une `NetworkPolicy` dans `endor` est censée autoriser `han` à le joindre — mais ça ne fonctionne pas.
- Dans **kamino** : le pod `lando`. Dans **mustafar** : les pods `wedge` et `biggs`. Une `NetworkPolicy` dans `mustafar` est censée autoriser à la fois le trafic venant de `kamino`, et le trafic entre les pods de `mustafar` eux-mêmes — mais rien ne passe.
- Un raccourci `k` (identique à `kubectl`).

C'est parti !
