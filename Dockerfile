FROM sagemathinc/cocalc

#Install useful utilities missing in original CoCalc image
RUN sed -i -e 's/archive.ubuntu.com\|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list && apt-get update 
RUN apt-get install -y --no-install-recommends \
	curl \
	ca-certificates \
        nano \
        gnuplot \
	wget \
	bzip2 \
        g++-5 \
        gcc-5 \
        ca-certificates \
        libglib2.0-0 \
        libxext6 \
        libsm6 \
        libxrender1 \
        git mercurial subversion \
        hugo
RUN curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1704/x86_64/7fa2af80.pub | apt-key add -
RUN echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1704/x86_64 /" > /etc/apt/sources.list.d/cuda.list

#Install CUDA and friends
LABEL com.nvidia.volumes.needed="nvidia_driver_384.98"
ENV CUDA_VERSION 9.1.85
ENV CUDA_PKG_VERSION 9-1=$CUDA_VERSION-1
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-cudart-$CUDA_PKG_VERSION \
	cuda-libraries-$CUDA_PKG_VERSION \
        cuda-libraries-dev-$CUDA_PKG_VERSION \
        cuda-nvml-dev-$CUDA_PKG_VERSION \
        cuda-minimal-build-$CUDA_PKG_VERSION \
        cuda-command-line-tools-$CUDA_PKG_VERSION \
	cuda-nvrtc-$CUDA_PKG_VERSION \
 	cuda-nvgraph-$CUDA_PKG_VERSION \
	cuda-cusolver-$CUDA_PKG_VERSION \
        cuda-cublas-$CUDA_PKG_VERSION \
        cuda-cufft-$CUDA_PKG_VERSION \
        cuda-curand-$CUDA_PKG_VERSION \
        cuda-cusparse-$CUDA_PKG_VERSION \
        cuda-npp-$CUDA_PKG_VERSION \
        cuda-core-$CUDA_PKG_VERSION \
        cuda-misc-headers-$CUDA_PKG_VERSION \
        cuda-nvrtc-dev-$CUDA_PKG_VERSION \
        cuda-nvgraph-dev-$CUDA_PKG_VERSION \
        cuda-cusolver-dev-$CUDA_PKG_VERSION \
        cuda-cublas-dev-$CUDA_PKG_VERSION \
        cuda-cufft-dev-$CUDA_PKG_VERSION \
        cuda-curand-dev-$CUDA_PKG_VERSION \
        cuda-cusparse-dev-$CUDA_PKG_VERSION \
        cuda-npp-dev-$CUDA_PKG_VERSION \
        cuda-cudart-dev-$CUDA_PKG_VERSION \
        cuda-driver-dev-$CUDA_PKG_VERSION \
        cuda-samples-$CUDA_PKG_VERSION && \
    ln -s cuda-9.1 /usr/local/cuda && \
    ln -s /usr/bin/gcc-5 /usr/local/cuda/bin/gcc && \
    ln -s /usr/bin/g++-5 /usr/local/cuda/bin/g++ && \
    rm -rf /var/lib/apt/lists/*

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=9.1"

#Install CuDNN (using this hack since CuDNN does not support 17.04)
ENV CUDNN_VERSION 7.0.5.15
LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"

RUN wget "http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7_7.0.5.15-1+cuda9.1_amd64.deb" -O "cudnn.deb" && \
    wget "http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64/libcudnn7-dev_7.0.5.15-1+cuda9.1_amd64.deb" -O "cudnndev.deb" && \
    dpkg -i cudnn.deb && \
    cp /usr/lib/x86_64-linux-gnu/libcudnn* /usr/local/cuda/lib64 && \
    rm cudnn.deb && \
    dpkg -i cudnndev.deb && \
    cp /usr/include/x86_64-linux-gnu/cudnn_v7.h /usr/local/cuda/include/cudnn.h && \
    rm cudnndev.deb

#Install CUDA path variables
RUN echo "/usr/local/cuda/lib64" >> /etc/ld.so.conf.d/cuda.conf && \
    ldconfig
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf
ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

#Install Anaconda
RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh

#Install Python packages (incl. Theano, Keras and PyTorch)
RUN /opt/conda/bin/conda install pytorch torchvision -c pytorch && \
    /opt/conda/bin/conda install -c menpo opencv3 && \
    /opt/conda/bin/conda install -y ipykernel matplotlib pydot-ng theano pygpu bcolz paramiko keras seaborn graphviz scikit-learn

#RUN /opt/conda/bin/conda install -c calex sklearn-pandas

ENV PATH /opt/conda/bin:${PATH}
ENV PATH /usr/local/cuda-9.1/bin:${PATH}
RUN echo 'export PATH=/usr/local/cuda-9.1/bin${PATH:+:${PATH}}' >> ~/.bashrc && \
    echo 'export PATH=/opt/conda/bin${PATH:+:${PATH}}' >> ~/.bashrc

#Add Conda kernel to Jupyter
RUN python -m ipykernel install --prefix=/usr/local/ --name "anaconda_kernel"

#Start CuCalc

CMD /root/run.py

EXPOSE 80 443
