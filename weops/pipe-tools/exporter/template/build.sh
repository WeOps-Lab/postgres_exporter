#!/bin/bash

for version in v9-4 v9-5 v9-6 v10-19 v11-0 v12-0 v13-0 v14-0 v15-0; do
  # 单点
  standalone_output_file="standalone_${version}.yaml"
  if [[ "$version" =~ ^(v9-4|v9-5|v9-6)$ ]]; then
    sed "s/{{VERSION}}/${version}/g; s/{{QUERYCONFIGMAP}}/pg-extend-queries-old/g" standalone.tpl > ../standalone/${standalone_output_file}
  else
    sed "s/{{VERSION}}/${version}/g; s/{{QUERYCONFIGMAP}}/pg-extend-queries/g" standalone.tpl > ../standalone/${standalone_output_file}
  fi

  # 集群
  for architecture in primary secondary; do
    cluster_output_file="cluster_${architecture}_${version}.yaml"
    if [[ "$version" =~ ^(v9-4|v9-5|v9-6)$ ]]; then
      sed "s/{{VERSION}}/${version}/g; s/{{ARCHITECTURE}}/${architecture}/g; s/{{QUERYCONFIGMAP}}/pg-extend-queries-old/g" cluster.tpl >> ../cluster/${cluster_output_file}
    else
      sed "s/{{VERSION}}/${version}/g; s/{{ARCHITECTURE}}/${architecture}/g; s/{{QUERYCONFIGMAP}}/pg-extend-queries/g" cluster.tpl >> ../cluster/${cluster_output_file}
    fi
  done
done

for version in v15-0; do
  # 集群高可用
  cluster_ha_output_file="cluster_ha_${version}.yaml"
  sed "s/{{VERSION}}/${version}/g; s/{{QUERYCONFIGMAP}}/pg-extend-queries/g" cluster_ha.tpl >> ../cluster_ha/${cluster_ha_output_file}
done
