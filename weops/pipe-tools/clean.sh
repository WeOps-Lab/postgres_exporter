#!/bin/bash
kubectl delete -f ./exporter -n postgres
kubectl delete -f ./exporter/standalone -n postgres

# 卸载监控对象
cd charts
bash helm_uninstall.sh

