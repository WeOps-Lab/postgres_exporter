#!/bin/bash

for version in v9-4 v9-5 v9-6 v10-19 v11-0 v12-0 v13-0 v14-0 v15-0; do
  # 单点
  standalone_output_file="standalone_${version}.yaml"
  sed "s/{{VERSION}}/${version}/g" standalone.tpl > ../standalone/${standalone_output_file}

  # 集群
  for architecture in primary secondary; do
    cluster_output_file="cluster_${architecture}_${version}.yaml"
    sed "s/{{VERSION}}/${version}/g; s/{{ARCHITECTURE}}/${architecture}/g" cluster.tpl >> ../cluster/${cluster_output_file}
  done
done
