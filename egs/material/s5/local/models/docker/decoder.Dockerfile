FROM kaldi-base:v1

# set path so we don't have to try to run path.sh 
# like we're doing a training experiment
ENV KALDI_ROOT "/kaldi"
ENV PATH "$PATH:$KALDI_ROOT/tools/sph2pipe_v2.5:$KALDI_ROOT/egs/material/s5/utils"

CMD ["/bin/bash"]

