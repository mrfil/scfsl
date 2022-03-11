# Timestamp: 2020/05/26 01:27:20 UTC
# 
# Thank you for using Neurodocker. If you discover any issues
# or ways to improve this software, please submit an issue or
# pull request on our GitHub repository:
# 
#     https://github.com/ReproNim/neurodocker

# https://ngc.nvidia.com/catalog/containers/nvidia:cuda
ARG CUDA_VERSION=10.2-cudnn7-runtime-ubuntu18.04
FROM nvcr.io/nvidia/cuda:10.2-cudnn7-runtime-ubuntu18.04
# FROM nvcr.io/nvidia/tensorflow:21.08-tf2-py3

USER root

ARG DEBIAN_FRONTEND="noninteractive"

ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN export ND_ENTRYPOINT="/neurodocker/startup.sh" \
    && apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           apt-utils \
           bzip2 \
           ca-certificates \
           curl \
           locales \
           unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG="en_US.UTF-8" \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir -p /neurodocker \
    && if [ ! -f "$ND_ENTRYPOINT" ]; then \
         echo '#!/usr/bin/env bash' >> "$ND_ENTRYPOINT" \
    &&   echo 'set -e' >> "$ND_ENTRYPOINT" \
    &&   echo 'export USER="${USER:=`whoami`}"' >> "$ND_ENTRYPOINT" \
    &&   echo 'if [ -n "$1" ]; then "$@"; else /usr/bin/env bash; fi' >> "$ND_ENTRYPOINT"; \
    fi \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker

ENTRYPOINT ["/neurodocker/startup.sh"]

ENV FSLDIR="/opt/fsl-6.0.3" \
    PATH="/opt/fsl-6.0.3/bin:$PATH" \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLMULTIFILEQUIT="TRUE" \
    FSLTCLSH="/opt/fsl-6.0.3/bin/fsltclsh" \
    FSLWISH="/opt/fsl-6.0.3/bin/fslwish" \
    FSLLOCKDIR="" \
    FSLMACHINELIST="" \
    FSLREMOTECALL="" \
    FSLGECUDAQ="cuda.q"
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           bc \
           dc \
           file \
           libfontconfig1 \
           libfreetype6 \
           libgl1-mesa-dev \
           libgl1-mesa-dri \
           libglu1-mesa-dev \
           libgomp1 \
           libice6 \
           libxcursor1 \
           libxft2 \
           libxinerama1 \
           libxrandr2 \
           libxrender1 \
           libxt6 \
           sudo \
           wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "Downloading FSL ..." \
    && mkdir -p /opt/fsl-6.0.3 \
    && curl -fsSL --retry 5 https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-6.0.3-centos6_64.tar.gz \
    | tar -xz -C /opt/fsl-6.0.3 --strip-components 1 \
    && sed -i '$iecho Some packages in this Docker container are non-free' $ND_ENTRYPOINT \
    && sed -i '$iecho If you are considering commercial use of this container, please consult the relevant license:' $ND_ENTRYPOINT \
    && sed -i '$iecho https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence' $ND_ENTRYPOINT \
    && sed -i '$isource $FSLDIR/etc/fslconf/fsl.sh' $ND_ENTRYPOINT \
    && echo "Installing FSL conda environment ..." \
    && bash /opt/fsl-6.0.3/etc/fslconf/fslpython_install.sh -f /opt/fsl-6.0.3

VOLUME ["/data"]

VOLUME ["/scripts"]

WORKDIR /scripts

LABEL maintainer="Paul B Camacho <pcamach2@illinois.edu>"

ENV PATH="/opt/mricron-latest:$PATH"
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           libgtk2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "Downloading MRIcron ..." \
    && mkdir -p /opt/mricron-latest \
    && curl -fsSL --retry 5 -O https://github.com/neurolabusc/MRIcron/releases/latest/download/MRIcron_linux.zip \
    && unzip "*cron*.zip" \
    && rm -f "*cron*.zip" \
    && mv mricron/* /opt/mricron-latest \
    && rmdir mricron

RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           libgl1-mesa-dev \
           libgomp1 \
           libice6 \
           libjpeg62 \
           libsm6 \
           libx11-6 \
           libxext6 \
           libxi6 \
           libxmu6 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "Downloading MINC, BEASTLIB, and MODELS..." \
    && mkdir -p /opt/minc-1.9.15 \
    && curl -fsSL --retry 5 https://dl.dropbox.com/s/40hjzizaqi91373/minc-toolkit-1.9.15-20170529-CentOS_6.9-x86_64.tar.gz \
    | tar -xz -C /opt/minc-1.9.15 --strip-components 1 \
    && curl -fsSL --retry 5 http://packages.bic.mni.mcgill.ca/tgz/beast-library-1.1.tar.gz \
    | tar -xz -C /opt/minc-1.9.15/share \
    && curl -fsSL --retry 5 -o /tmp/mni_90a.zip http://www.bic.mni.mcgill.ca/~vfonov/icbm/2009/mni_icbm152_nlin_sym_09a_minc2.zip \
    && unzip /tmp/mni_90a.zip -d /opt/minc-1.9.15/share/icbm152_model_09a \
    && curl -fsSL --retry 5 -o /tmp/mni_90c.zip http://www.bic.mni.mcgill.ca/~vfonov/icbm/2009/mni_icbm152_nlin_sym_09c_minc2.zip \
    && unzip /tmp/mni_90c.zip -d /opt/minc-1.9.15/share/icbm152_model_09c \
    && sed -i 's+MINC_TOOLKIT=/opt/minc+MINC_TOOLKIT=/opt/minc-1.9.15+g' /opt/minc-1.9.15/minc-toolkit-config.sh \
    && sed -i '$isource /opt/minc-1.9.15/minc-toolkit-config.sh' $ND_ENTRYPOINT \
    && rm -rf /tmp/mni*

RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           python2.7 \
           curl \
           git \
           python-numpy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/afni-latest:$PATH" \
    AFNI_PLUGINPATH="/opt/afni-latest"
RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           ed \
           gsl-bin \
           libglib2.0-0 \
           libglu1-mesa-dev \
           libglw1-mesa \
           libgomp1 \
           libjpeg62 \
           libxm4 \
           netpbm \
           tcsh \
           xfonts-base \
           xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && curl -sSL --retry 5 -o /tmp/toinstall.deb http://mirrors.kernel.org/debian/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb \
    && dpkg -i /tmp/toinstall.deb \
    && rm /tmp/toinstall.deb \
    && curl -sSL --retry 5 -o /tmp/toinstall.deb http://snapshot.debian.org/archive/debian-security/20160113T213056Z/pool/updates/main/libp/libpng/libpng12-0_1.2.49-1%2Bdeb7u2_amd64.deb \
    && dpkg -i /tmp/toinstall.deb \
    && rm /tmp/toinstall.deb \
    && apt-get install -f \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && gsl2_path="$(find / -name 'libgsl.so.19' || printf '')" \
    && if [ -n "$gsl2_path" ]; then \
         ln -sfv "$gsl2_path" "$(dirname $gsl2_path)/libgsl.so.0"; \
    fi \
    && ldconfig \
    && echo "Downloading AFNI ..." \
    && mkdir -p /opt/afni-latest \
    && curl -fsSL --retry 5 https://afni.nimh.nih.gov/pub/dist/tgz/linux_openmp_64.tgz \
    | tar -xz -C /opt/afni-latest --strip-components 1

ENV fslpath="/opt/fsl-6.0.3"

RUN apt update && apt install -y python-pip nano
RUN apt-get install git
RUN pip install etelemetry nipype
RUN mkdir /fsl_sub && git clone https://github.com/neurolabusc/fsl_sub.git /fsl_sub
RUN cd /fsl_sub && cp ./fsl_sub /opt/fsl-6.0.3/bin/fsl_sub
COPY . /scripts
RUN ls
#RUN bash /scripts/proc_fsl_connectomePRE_TEST.sh

