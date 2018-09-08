FROM sagemathinc/cocalc

# Install useful utilities missing in original CoCalc image
# CUDA 9.2 is not officially supported on ubuntu 18.04 yet, we use the ubuntu 17.10 repository for CUDA instead.
RUN apt-get update && apt-get install -y --no-install-recommends \
        gnupg2 curl ca-certificates \
        nano gnuplot \
        g++-5 gcc-5 \
        libglib2.0-0 libxext6 libsm6 libxrender1 \
        mercurial subversion \
        epstool && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1710/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1710/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl && \
    rm -rf /var/lib/apt/lists/*


ENV CUDA_VERSION 9.2.148
ENV CUDA_PKG_VERSION 9-2=$CUDA_VERSION-1
ENV NCCL_VERSION 2.2.13

RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-cudart-$CUDA_PKG_VERSION \
        cuda-cudart-dev-$CUDA_PKG_VERSION \
        cuda-cupti-$CUDA_PKG_VERSION \
        cuda-libraries-$CUDA_PKG_VERSION \
        cuda-nvtx-$CUDA_PKG_VERSION \
        libnccl2=$NCCL_VERSION-1+cuda9.2 \
        cuda-libraries-dev-$CUDA_PKG_VERSION \
        cuda-nvml-dev-$CUDA_PKG_VERSION \
        cuda-minimal-build-$CUDA_PKG_VERSION \
        cuda-command-line-tools-$CUDA_PKG_VERSION \
        libnccl-dev=$NCCL_VERSION-1+cuda9.2 && \
    ln -s cuda-9.2 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

#Install CUDA path variables
ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LIBRARY_PATH /usr/local/cuda/lib64/stubs
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=9.2"

#Install CuDNN (using this hack since CuDNN does not support 17.04)
ENV CUDNN_VERSION 7.2.1.38
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

RUN apt-get update && apt-get install -y --no-install-recommends \
            libcudnn7=$CUDNN_VERSION-1+cuda9.2 \
            libcudnn7-dev=$CUDNN_VERSION-1+cuda9.2 && \
    rm -rf /var/lib/apt/lists/*

#Install Anaconda
RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh

#Install Python packages (incl. Theano, Keras and PyTorch)
RUN /opt/conda/bin/conda install -y ipykernel matplotlib pydot-ng theano pygpu bcolz paramiko keras seaborn graphviz scikit-learn cudatoolkit numba
RUN /opt/conda/bin/conda create -n xeus python=3.6 ipykernel xeus-cling -c QuantStack -c conda-forge
RUN /opt/conda/bin/conda create -n pytorch python=3.6 ipykernel pytorch torchvision cuda90 -c pytorch

ENV PATH /opt/conda/bin:${PATH}
ENV PATH /usr/local/cuda/bin:${PATH}
RUN echo 'export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}' >> /cocalc/src/smc_pyutil/smc_pyutil/templates/linux/bashrc && \
    echo 'export PATH=/opt/conda/bin${PATH:+:${PATH}}' >> /cocalc/src/smc_pyutil/smc_pyutil/templates/linux/bashrc

#Add Conda kernel to Jupyter
RUN python -m ipykernel install --prefix=/usr/local/ --name "anaconda_kernel"

#Start CuCalc

CMD /root/run.py

EXPOSE 80 443
