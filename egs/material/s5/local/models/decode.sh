#!/bin/bash

# begin configuration section.
decode_mbr=false
beam=6
word_ins_penalty=1.0
min_lmwt=7
max_lmwt=17
filter=wer_output_filter
# end configuration section.

echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;

modeldir=$1
wav=$2
segments=$3
dir=$4

mkdir -p $dir

sed "s|__modeldir__|${modeldir}|" $modeldir/conf/mfcc_hires.conf | \
    sed "s|__confdir__|${modeldir}/conf|" > $dir/mfcc.conf
sed "s|__modeldir__|${modeldir}|" $modeldir/conf/ivector_extractor.conf | \
    sed "s|__confdir__|${modeldir}/conf|" > $dir/ivector_extractor.conf

awk '{ print $1, $2 }'  < $segments > $dir/utt2spk
utt2spk_to_spk2utt.pl $dir/utt2spk > $dir/spk2utt

extract-segments scp,p:$wav $segments ark:- | \
    compute-mfcc-feats --verbose=2 --config=$dir/mfcc.conf ark:- ark:- | \
    copy-feats --compress=true ark:- ark,scp:$dir/feats.ark,$dir/feats.scp

compute-cmvn-stats --spk2utt=ark:$dir/spk2utt scp:$dir/feats.scp \
                   ark,scp:$dir/cmvn.ark,$dir/cmvn.scp

echo ivector-extract-online2 --config=$dir/ivector_extractor.conf \
                        ark:$dir/spk2utt \
                        scp:$dir/feats.scp ark:- \| \
    copy-feats --compress=true ark:- \
               ark,scp:$dir/ivector_online.ark,$dir/ivector_online.scp

ivector-extract-online2 --config=$dir/ivector_extractor.conf \
                        ark:$dir/spk2utt \
                        scp:$dir/feats.scp ark:- | \
    copy-feats --compress=true ark:- \
               ark,scp:$dir/ivector_online.ark,$dir/ivector_online.scp

nnet3-latgen-faster-parallel --num-threads=4 \
                             --online-ivectors=scp:$dir/ivector_online.scp \
                             --online-ivector-period=10 --frame-subsampling-factor=3 \
                             --frames-per-chunk=140 --extra-left-context=40 \
                             --extra-right-context=0 --extra-left-context-initial=0 \
                             --extra-right-context-final=0 --minimize=false \
                             --max-active=7000 --min-active=200 --beam=15.0 --lattice-beam=8.0 \
                             --acoustic-scale=1.0 --allow-partial=true \
                             --word-symbol-table=$modeldir/graph/words.txt \
                             $modeldir/final.mdl \
                             $modeldir/graph/HCLG.fst \
                             "ark,s,cs:apply-cmvn --norm-means=false --norm-vars=false --utt2spk=ark:$dir/utt2spk scp:$dir/cmvn.scp scp:$dir/feats.scp ark:- |" \
                             "ark:|lattice-scale --acoustic-scale=10.0 ark:- ark:- | gzip -c > $dir/lat.gz"

if $decode_mbr ; then
    echo "$0: decoding with MBR, word insertion penalty=$word_ins_penalty"
else
    echo "$0: decoding with word insertion penalty=$word_ins_penalty"
fi

wip=$word_ins_penalty
mkdir -p $dir/scoring_kaldi/penalty_$wip/log
symtab=$modeldir/graph/words.txt
hyp_filtering_cmd=$modeldir/scripts/$filter

for LMWT in `seq $min_lmwt $max_lmwt` ; do
    #    $cmd LMWT=$min_lmwt:$max_lmwt $dir/scoring_kaldi/penalty_$wip/log/best_path.LMWT.log \
    if $decode_mbr ; then
        lattice-scale --inv-acoustic-scale=$LMWT "ark:gunzip -c $dir/lat.gz|" ark:- | \
                      lattice-add-penalty --word-ins-penalty=$wip ark:- ark:- | \
                      lattice-prune --beam=$beam ark:- ark:- | \
                      lattice-mbr-decode  --word-symbol-table=$symtab \
                      ark:- ark,t:- | \
                      utils/int2sym.pl -f 2- $symtab | \
                      $hyp_filtering_cmd > $dir/transcript.txt || exit 1;
        
    else
        lattice-scale --inv-acoustic-scale=$LMWT "ark:gunzip -c $dir/lat.gz|" ark:- | \
                      lattice-add-penalty --word-ins-penalty=$wip ark:- ark:- | \
                      lattice-best-path --word-symbol-table=$symtab ark:- ark,t:- | \
                      utils/int2sym.pl -f 2- $symtab | \
                      $hyp_filtering_cmd > $dir/transcript.txt || exit 1;
    fi

    lattice-scale --inv-acoustic-scale=$LMWT "ark:gunzip -c $dir/lat.gz|" ark:- | \
        lattice-add-penalty --word-ins-penalty=$wip ark:- ark:- | \
        lattice-to-ctm-conf --decode-mbr=$decode_mbr  ark:- - | \
        utils/int2sym.pl -f 5 $symtab > $dir/transcript.ctm
                      
    
done
