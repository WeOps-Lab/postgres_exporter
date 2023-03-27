#!/bin/bash

# 部署监控对象
object=postgres
object_versions=("9.4.6" "9.5.2-0" "9.6" "10.0" "12.0.0" "13.0.0" "14.0.0" "15.0.0")

for version in "${object_versions[@]}"; do
    version_suffix="v${version%%.*}.${version%.*.*}"
    version_suffix=${version_suffix//./-}

    helm install pg-standalone-$version_suffix --namespace $object -f ./values/bitnami_values.yaml ./postgres \
    --set image.tag=$version \
    --set commonLabels.object_version=$version_suffix
done