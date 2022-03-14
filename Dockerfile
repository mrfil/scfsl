# Generated by: Neurodocker version 0.7.0
# https://github.com/ReproNim/neurodocker

# https://ngc.nvidia.com/catalog/containers/nvidia:cuda
# old version used - 9.1-cudnn7-runtime-ubuntu16.04
ARG CUDA_VERSION=10.2-cudnn7-runtime-ubuntu18.04
FROM nvcr.io/nvidia/cuda:10.2-cudnn7-runtime-ubuntu18.04

USER root

WORKDIR /workspace

ARG DEBIAN_FRONTEND="noninteractive"

ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"

RUN export ND_ENTRYPOINT="/neurodocker/startup.sh" \
    && apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           libopenblas-dev \
           apt-utils \
           bzip2 \
           ca-certificates \
           curl \
           locales \
           unzip \
    # && apt-get clean \
    # && rm -rf /var/lib/apt/lists/* \
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

ENV FSLDIR="/opt/fsl-6.0.5.1" \
    PATH="/opt/fsl-6.0.5.1/bin:$PATH" \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLMULTIFILEQUIT="TRUE" \
    FSLTCLSH="/opt/fsl-6.0.5.1/bin/fsltclsh" \
    FSLWISH="/opt/fsl-6.0.5.1/bin/fslwish" \
    FSLLOCKDIR="" \
    FSLMACHINELIST="" \
    FSLREMOTECALL="" \
    FSLGECUDAQ="cuda.q"

RUN apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           bc \
           dc \
           file \
           unzip \
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
           python2.7 \
           python-pip \
           nano \
           python-numpy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "Downloading FSL ..." \
    && mkdir -p /opt/fsl-6.0.5.1 \
    && curl -fsSL --retry 5 https://fsl.fmrib.ox.ac.uk/fsldownloads/fsl-6.0.5.1-centos7_64.tar.gz \
    | tar -xz -C /opt/fsl-6.0.5.1 --strip-components 1 \
    && sed -i '$iecho Some packages in this Docker container are non-free' $ND_ENTRYPOINT \
    && sed -i '$iecho If you are considering commercial use of this container, please consult the relevant license:' $ND_ENTRYPOINT \
    && sed -i '$iecho https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence' $ND_ENTRYPOINT \
    && sed -i '$isource $FSLDIR/etc/fslconf/fsl.sh' $ND_ENTRYPOINT \
    && echo "Installing FSL conda environment ..." \
    && bash /opt/fsl-6.0.5.1/etc/fslconf/fslpython_install.sh -f /opt/fsl-6.0.5.1

RUN curl -fsSL --retry 5 https://users.fmrib.ox.ac.uk/~moisesf/Bedpostx_GPU/FSL_6/CUDA_10.2/bedpostx_gpu.zip \
   | unzip -d /opt/bedpostx_gpu_cuda10.2 \
   && mv /opt/bedpostx_gpu_cuda10.2/lib/* /opt/fsl-6.0.5.1/lib/ \
   && mv /opt/bedpostx_gpu_cuda10.2/bin/* /opt/fsl-6.0.5.1/bin/ \
   && curl -fsSL --retry 5 https://users.fmrib.ox.ac.uk/~moisesf/Probtrackx_GPU/FSL_6/CUDA_10.2/probtrackx2_gpu.zip \
   | unzip -d /opt/probtrackx2_gpu_cuda10.2 \
   && mv /opt/probtrackx2_gpu_cuda10.2/lib/* /opt/fsl-6.0.5.1/lib/ \
   && mv /opt/probtrackx2_gpu_cuda10.2/bin/* /opt/fsl-6.0.5.1/bin/

# Add conda to path
ENV PATH="/opt/fsl-6.0.5.1/fslpython/condabin:/opt/fsl-6.0.5.1/fslpython/bin:${PATH}" 

RUN pip install etelemetry nipype

COPY scripts /scripts
