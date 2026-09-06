# Bravo !

Tu as pratiqué une méthodologie de troubleshooting bas niveau du
control plane Kubernetes :

- Diagnostiqué une panne de `kube-apiserver` en comparant plusieurs
  sources : `/var/log/pods`, `/var/log/containers`, `crictl`,
  `journalctl -u kubelet`.
- Compris pourquoi `crictl` et `journalctl` restent indispensables
  quand `kubectl` lui-même ne fonctionne plus.
- Observé trois signatures d'erreur différentes : argument de ligne de
  commande invalide, cible etcd injoignable, et manifest invalide pour
  kubelet.

## Pour aller plus loin

- Recommence l'exercice sur `kube-controller-manager` ou
  `kube-scheduler` : les manifests suivent la même logique.
- Regarde ce qui se passe si tu casses le manifest d'`etcd`
  lui-même : conséquences en cascade sur tout le control plane.
- `journalctl -u kubelet -f` en continu pendant que tu modifies un
  manifest, pour observer la réaction de kubelet en temps réel.
