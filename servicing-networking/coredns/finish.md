# Bravo !

Tu as :

- Diagnostiqué un `CrashLoopBackOff` provoqué par une directive
  inconnue dans le `Corefile` du ConfigMap `coredns`, en partant des
  logs jusqu'à la configuration en cause.
- Déployé une application standard (`Deployment` + `Service`
  `ClusterIP`).
- Observé la découverte de service Kubernetes en pratique : un pod
  d'un namespace peut joindre un Service d'un autre namespace via le
  simple nom court `<service>.<namespace>`, résolu par CoreDNS.

## Pour aller plus loin

- Inspecte le `Corefile` par défaut (`kubectl get cm coredns -n
  kube-system -o yaml`) et regarde le rôle de chaque plugin
  (`errors`, `health`, `kubernetes`, `forward`, `cache`, `loop`...).
- Compare `<service>.<namespace>` avec la forme pleinement qualifiée
  `<service>.<namespace>.svc.cluster.local` et regarde
  `/etc/resolv.conf` dans un pod pour comprendre pourquoi la forme
  courte fonctionne (`search` domains).
