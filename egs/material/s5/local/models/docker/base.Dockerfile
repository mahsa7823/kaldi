FROM centos:7
ONBUILD RUN yum install -y epel-release
ONBUILD RUN yum install -y python34

ONBUILD RUN yum install -y which gawk gcc gcc-c++ make automake libtool-bin git autoconf && \
            yum install -y subversion atlas.x86_64 blas.x86_64 lapack.x86_64 gzip bzip2 wget python && \
	    yum install -y zlib-devel patch libtool sox sox-devel
	    
#ONBUILD RUN git clone https://github.com/mahsa7823/kaldi.git --depth=1
# jw16 is a fork of mahsa7823 w/ the docker decoder added
ONBUILD RUN git clone -b material_basic --single-branch https://github.com/jw16/kaldi.git

ONBUILD RUN cd /kaldi/tools && make
ONBUILD RUN cd /kaldi/src && ./configure --shared && make depend -j 2  && make -j 2 

CMD ["/bin/bash"]

