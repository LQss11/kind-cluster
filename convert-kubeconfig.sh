#!/bin/bash
export HOST=localhost
export OLD_HOST=$(cat /root/.kube/config  | grep server | cut -d/ -f3 | cut -d: -f1)
export PORT=$(docker ps | grep $(echo $OLD_HOST) | awk '{print $10}' | cut -d: -f2 | cut -d- -f1)
cp /root/.kube/config /root/.kube/kindconfig
sed -i "s/$OLD_HOST/$HOST/g;s/6443/$PORT/g" /root/.kube/kindconfig