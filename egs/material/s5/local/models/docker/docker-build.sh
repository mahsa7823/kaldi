#!/bin/bash

if [ -z $KALDI_ROOT ]; then
   echo "Please specify the KALDI_ROOT variable\n"
   exit 1
fi

docker build -t kaldi-base:v1 - < $KALDI_ROOT/egs/material/s5/local/models/docker/base.Dockerfile
docker build -t kaldi-decoder:v1 - < $KALDI_ROOT/egs/material/s5/local/models/docker/decoder.Dockerfile

exit 0
