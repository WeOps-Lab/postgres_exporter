#!/bin/bash

# 设置需要删除的对象的名称空间
object="postgres"

# 删除 Helm chart
echo "Uninstalling $object releases ..."
for RELEASE in $(helm list -n $object --short)
do
  helm uninstall -n $object $RELEASE
done

