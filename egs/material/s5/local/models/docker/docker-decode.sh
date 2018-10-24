#!/bin/bash

# Copyright (c) 2018, Johns Hopkins University (Jonathan Wintrode<jonathan.wintrode@gmail.com>)
# License: Apache 2.0

# Run the decode.sh script using the docker containers 
# built via the base.Dockerfile and decoder.Dockerfile
# and using models compiled with the make_mpack.sh
#
# Currently we take the Kaldi-style wav.scp and segments
# and relocate the audio to a sharable path mounted as
# /data.  The output directory needs to be writable by 
# all, unless a more complex permissions scheme is 
# required by the docker container.  

models=$1
data=$2
output=$3
wavscp=$4

segments=$5

# path to prepare_wavscp
bindir="$( cd "$( dirname "$0" )" && pwd )"

mkdir -p $data/audio

if [ -f $wavscp ]; then
    # external wavscp and segments
    if [ ! -f $data/wav.scp.orig ]; then
        cp $wavscp $data/wav.scp.orig
    fi
    $bindir/prepare_wavscp.pl $data/wav.scp.orig $data/audio > $data/wav.scp
else
    echo "Cannot read wav.scp : $wavscp"
fi

if [ -f $segments ]; then
    if [ `realpath $segments` != `realpath $data/segments` ]; then
      cp $segments $data/segments
    fi
else
    echo "Warning:  No segments file provided, creating 30s segments."
fi

docker run -v $models:/model -v $data:/data -v $output:/output \
	kaldi-decoder:v1 \
	/kaldi/egs/material/s5/local/models/decode.sh \
	/model /data/wav.scp /data/segments /output


