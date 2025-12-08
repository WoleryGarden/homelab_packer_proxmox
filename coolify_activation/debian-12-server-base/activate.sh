#!/bin/bash

touch /activate
while [ ! -f /done ]; do sleep 10; done
retVal="$(cat /done)"
rm /done
if [ "0" == "$retVal" ]; then exit 0; else exit 1; fi
