#!/bin/bash

# 设置需要删除的对象的名称空间
object="postgres"

# 删除监控对象
object=postgres
object_versions=("9.4.6" "9.5.2-0" "9.6" "10.19.0" "11.0.0" "12.0.0" "13.0.0" "14.0.0" "15.0.0")

for version in "${object_versions[@]}"; do
    version_suffix="v$(echo "$version" | grep -Eo '[0-9]{1,2}\.[0-9]{1,2}' | tr '.' '-')"

    # 单点
    helm uninstall pg-standalone-$version_suffix --namespace $object

    # 集群
    helm uninstall pg-cluster-$version_suffix --namespace $object

    # 集群高可用
    if [[ $version == "15.0.0" ]]; then
      helm uninstall pg-cluster-ha-$version_suffix --namespace $object
    fi

done


# 删除 Helm chart
echo "Uninstalling $object releases ..."
for RELEASE in $(helm list -n $object --short)
do
  helm uninstall -n $object $RELEASE
done