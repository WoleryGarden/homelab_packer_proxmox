#!/bin/bash

while true
do
  echo "waiting for activations"
  while [ ! -f /activate ]; do sleep 10; done
  rm /activate
  echo "activation recieved, waking up"
  packer init .
  packer build -force .
done
