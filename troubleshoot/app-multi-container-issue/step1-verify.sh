#!/bin/bash
LOGFILE="/root/logs.log"

if [ ! -f "$LOGFILE" ]; then
  echo "❌ $LOGFILE n'existe pas"
  exit 1
fi
echo "✅ $LOGFILE existe"

if [ ! -s "$LOGFILE" ]; then
  echo "❌ $LOGFILE est vide"
  exit 1
fi
echo "✅ $LOGFILE n'est pas vide"

if ! grep -qi "nginx" "$LOGFILE"; then
  echo "❌ Aucune trace du conteneur nginx dans $LOGFILE"
  exit 1
fi
echo "✅ Logs du conteneur nginx présents"

if ! grep -qi "httpd" "$LOGFILE"; then
  echo "❌ Aucune trace du conteneur httpd dans $LOGFILE"
  exit 1
fi
echo "✅ Logs du conteneur httpd présents"

exit 0
