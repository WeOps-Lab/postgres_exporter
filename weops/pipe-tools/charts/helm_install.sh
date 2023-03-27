#!/bin/bash

# 部署监控对象
object=postgres

helm install pg --namespace $object -f ./values/bitnami_values.yaml ./postgres \
--set image.tag=15.2.0