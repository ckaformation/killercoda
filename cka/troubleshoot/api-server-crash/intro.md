# Troubleshooting kube-apiserver

Ce scénario aborde une méthodologie de troubleshooting bas niveau :
comment diagnostiquer une panne de `kube-apiserver` quand `kubectl`
lui-même ne fonctionne plus, puisqu'il en dépend ?

Le manifest du pod statique `kube-apiserver`
(`/etc/kubernetes/manifests/kube-apiserver.yaml`) va être modifié à
plusieurs reprises pour provoquer différents types de panne. À chaque
fois, tu chercheras la cause à l'aide d'outils qui ne dépendent pas de
l'apiserver : `crictl`, les logs sous `/var/log`, et `journalctl`.

Le cluster démarre sur une base saine, sans erreur : c'est toi qui vas
introduire chaque panne, la diagnostiquer, puis restaurer le manifest
d'origine.

Pas de vérification automatique sur ce scénario : on avance ensemble,
étape par étape.
