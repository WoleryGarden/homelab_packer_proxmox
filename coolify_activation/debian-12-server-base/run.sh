#!/bin/bash

while true
do
  echo "waiting for activations"
  while [ ! -f /activate ]; do sleep 10; done
  rm /activate
  echo "activation received, waking up"
  packer init .
  retVal=$?
  if [ $retVal -ne 0 ]; then
    echo "packer init failed"
    echo -n "$retVal" > /done
    continue
  fi
  packer build -force .
  retVal=$?
  if [ $retVal -ne 0 ]; then
    echo "packer build failed"
  fi
  echo -n "$retVal" > /done
done
