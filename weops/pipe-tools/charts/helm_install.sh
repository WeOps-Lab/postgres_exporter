#!/bin/bash

# 部署监控对象
object=postgres
object_versions=("9.4.6" "9.5.2-0" "9.6" "10.19.0" "11.0.0" "12.0.0" "13.0.0" "14.0.0" "15.0.0")

for version in "${object_versions[@]}"; do
    version_suffix="v$(echo "$version" | grep -Eo '[0-9]{1,2}\.[0-9]{1,2}' | tr '.' '-')"

    # 设置PodSecurityContext和ContainerSecurityContext
    if [[ $version == "9.4"* ]] || [[ $version == "9.5"* ]]; then
        pg_security_args="--set primary.podSecurityContext.fsGroup=0 --set primary.containerSecurityContext.runAsUser=0 --set readReplicas.podSecurityContext.fsGroup=0 --set readReplicas.containerSecurityContext.runAsUser=0"
    else
        pg_security_args=""
    fi

    # 单点
    helm install pg-standalone-$version_suffix --namespace $object -f ./values/bitnami_values.yaml ./postgres \
    --set image.tag=$version \
    --set commonLabels.object_version=$version_suffix \
    $pg_security_args

    # 集群
    helm install pg-cluster-$version_suffix --namespace $object -f ./values/bitnami_values.yaml ./postgres \
    --set image.tag=$version \
    --set architecture=replication \
    --set commonLabels.object_version=$version_suffix \
    $pg_security_args


    if [[ $version == "15.0.0" ]]; then
      helm install pg-cluster-ha-$version_suffix --namespace $object -f ./values/bitnami_ha_values.yaml ./postgres-ha \
      --set image.tag=$version \
      --set commonLabels.object_version=$version_suffix
    fi

    sleep 1
done

