FROM sagemathinc/cocalc

LABEL com.nvidia.volumes.needed="nvidia_driver_384.98"

RUN echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/cuda.list

ENV CUDA_VERSION 8.0.61
LABEL com.nvidia.cuda.version="${CUDA_VERSION}"

ENV CUDA_PKG_VERSION 8-0=$CUDA_VERSION-1
RUN apt-get update && apt-get install -y --allow-unauthenticated --no-install-recommends \
        cuda-nvrtc-$CUDA_PKG_VERSION \
        cuda-nvgraph-$CUDA_PKG_VERSION \
        cuda-cusolver-$CUDA_PKG_VERSION \
        cuda-cublas-8-0=8.0.61.1-1 \
        cuda-cufft-$CUDA_PKG_VERSION \
        cuda-curand-$CUDA_PKG_VERSION \
        cuda-cusparse-$CUDA_PKG_VERSION \
        cuda-npp-$CUDA_PKG_VERSION \
        cuda-cudart-$CUDA_PKG_VERSION \
	cuda-core-$CUDA_PKG_VERSION \
        cuda-misc-headers-$CUDA_PKG_VERSION \
        cuda-command-line-tools-$CUDA_PKG_VERSION \
        cuda-nvrtc-dev-$CUDA_PKG_VERSION \
        cuda-nvml-dev-$CUDA_PKG_VERSION \
        cuda-nvgraph-dev-$CUDA_PKG_VERSION \
        cuda-cusolver-dev-$CUDA_PKG_VERSION \
        cuda-cublas-dev-8-0=8.0.61.1-1 \
        cuda-cufft-dev-$CUDA_PKG_VERSION \
        cuda-curand-dev-$CUDA_PKG_VERSION \
        cuda-cusparse-dev-$CUDA_PKG_VERSION \
        cuda-npp-dev-$CUDA_PKG_VERSION \
        cuda-cudart-dev-$CUDA_PKG_VERSION \
        cuda-driver-dev-$CUDA_PKG_VERSION \
	cuda-samples-$CUDA_PKG_VERSION \
	g++-5 \
	gcc-5 \
	nano \
	gnuplot \
	wget \
	bzip2 \
	ca-certificates \
        libglib2.0-0 \
        libxext6 \
        libsm6 \
        libxrender1 \
    	git mercurial subversion && \
    ln -s cuda-8.0 /usr/local/cuda && \
    ln -s /usr/bin/gcc-5 /usr/local/cuda/bin/gcc && \
    ln -s /usr/bin/g++-5 /usr/local/cuda/bin/g++ && \
    rm -rf /var/lib/apt/lists/*

#Install CuDNN
RUN wget "http://files.fast.ai/files/cudnn.tgz" -O "cudnn.tgz" && \
    tar -zxf cudnn.tgz && \
    cd cuda && \
    sudo cp lib64/* /usr/local/cuda/lib64/ && \
    sudo cp include/* /usr/local/cuda/include/

RUN echo "/usr/local/cuda/lib64" >> /etc/ld.so.conf.d/cuda.conf && \
    ldconfig

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

#Install Anaconda

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/archive/Anaconda2-5.0.1-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh

#Install Theano and Keras
RUN /opt/conda/bin/conda install -y pydot-ng theano pygpu bcolz && \
    /opt/conda/bin/conda install -c conda-forge keras=1.2.2

ENV PATH /opt/conda/bin:${PATH}
ENV PATH /usr/local/cuda-8.0/bin:${PATH}
RUN echo 'export PATH=/usr/local/cuda-8.0/bin${PATH:+:${PATH}}' >> ~/.bashrc && \
    echo 'export PATH=/opt/conda/bin${PATH:+:${PATH}}' >> ~/.bashrc

RUN python -m ipykernel install --prefix=/usr/local/ --name "anaconda_kernel"

#Start CuCalc

CMD /root/run.py

EXPOSE 80 443
