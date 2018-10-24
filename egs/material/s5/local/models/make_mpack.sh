#!/bin/bash
# Copyright (c) 2018, Johns Hopkins University (Jonathan Wintrode <jonathan.wintrode@gmail.com>)
# License: Apache 2.0

# Model packaging for tdnn-lstm recipe decoder
#
# 

# Begin configuration section.
# End configuration section

lmwt=10
prefix=
feature_conf=conf/mfcc_hires.conf
ivector_conf=exp/nnet3/ivectors_train_sp_hires/conf/ivector_extractor.conf
iter=final
root=.

echo "$0 $@"  # Print the command line for logging
[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;

graphdir=$1
modeldir=$2
lpack=$3

bindir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# move all files to a temporary folder, the zip
if [ -z $TMP ]; then
    TMP=/tmp
fi

uuid=`cat /proc/sys/kernel/random/uuid`
lpdir=$TMP/kaldi-lp-$uuid

if [[ ! -d $lpdir ]]; then
    mkdir -p $lpdir
fi

# Copy all config files to the conf directory.
# Kaldi config files are usually made with paths
# relative to the experiment directory and often
# point to other config files
# We copy all nested config files and replace
# the relative paths with either the token
# __modeldir__ which is the root of the zip archive
# or __confdir__ which is __modeldir__/conf

mkdir -p $lpdir/conf

echo "# Parsing feature config files..."
python local/models/rewrite_config.py --root $root $root/$feature_conf $lpdir/conf $lpdir || exit 1

echo "# Parsing ivector config files..."
python local/models/rewrite_config.py --root $root $root/$ivector_conf $lpdir/conf $lpdir || exit 1

echo "# Copying nnet model $iter.model"
cp $modeldir/$iter.mdl $lpdir || exit 1

echo "# Copying decoding graph HCLG.fst, words.txt"
echo mkdir $lpdir/graph
mkdir $lpdir/graph

# Check for files in the graph directory to be sure
graphfiles=(HCLG.fst words.txt phones.txt disambig_tid.int phones/word_boundary.int)

for file in ${graphfiles[@]} ; do
    if [ ! -f $graphdir/$file ]; then
        echo "# Missing graph file $graphdir/$file"
        exit 1
    fi
    echo "cp $graphdir/$file $lpdir/graph"
    cp $graphdir/$file $lpdir/graph
done


# if a dev set is decoded, we could extract best LMWT
#lexicon=`grep ^lexicon_file local.conf| sed 's/lexicon_file=//'`
#if [[ -f $lexicon ]]; then
#    cp $lexicon $lpdir/lexicon.txt
#else
#    echo "Warning: Unable to find lexicon file $lexicon"
#fi
#echo optlmwt=$lmwt >> $lpdir/local.conf
#touch $lpdir/conf/decode.config

mkdir $lpdir/scripts

cp $root/local/wer_output_filter $lpdir/scripts

# zip the files to the destination $lpack

fullpath=`readlink -f $lpack`
pushd $lpdir
zip -r $fullpath *
popd
rm -rf $lpdir

exit 0
