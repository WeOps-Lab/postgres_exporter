#!/bin/bash

for version in v5-5 v5-6 v5-7 v8-0-32; do
  # 单点
  standalone_output_file="standalone_${version}.yaml"
  sed "s/{{VERSION}}/${version}/g" standalone.tpl > ../standalone/${standalone_output_file}
done
