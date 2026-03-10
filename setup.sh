#!/bin/bash
echo "Waiting for background installation to finish..."
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do 
  sleep 5
done