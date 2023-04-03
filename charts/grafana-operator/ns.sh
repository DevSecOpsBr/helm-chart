#!/bin/bash

for f in $(ls templates/*.yaml)
do 
  echo "renaming: $f"
  sed -i '' "s/grafana-operator-system/monitoring/g" $f 
  echo "renamed $f"
done

