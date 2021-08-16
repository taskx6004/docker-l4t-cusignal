FROM nvcr.io/nvidia/l4t-base:r32.6.1
ENV DEBIAN_FRONTEND noninteractive

# Fetch
RUN apt-get update && apt upgrade -yf 
RUN apt-get install -y sudo wget git ca-certificates libssl1.1 build-essential g++
RUN update-ca-certificates

WORKDIR /app
RUN wget https://github.com/conda-forge/miniforge/releases/download/4.10.3-4/Mambaforge-4.10.3-4-Linux-aarch64.sh

RUN mkdir -p /app/conda \
    && bash /app/Mambaforge-4.10.3-4-Linux-aarch64.sh -b \
    && rm -f /app/Mambaforge-4.10.3-4-Linux-aarch64.sh

# Deploy Conda
ENV PATH="/root/mambaforge/bin:${PATH}"
ARG PATH="/root/mambaforge/bin:${PATH}"
ENV PATH="/usr/local/cuda/bin:${PATH}"
ARG MAKEFLAGS=-j$(nproc) 
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"
ENV CUDA_HOME="/usr/local/cuda"
#RUN conda --version

# Prepare cusignal
COPY ./cusignal_jetson_base.yml /app/
RUN conda env create --file /app/cusignal_jetson_base.yml
RUN conda init bash
SHELL ["/bin/bash", "-c"]
RUN echo ". activate cusignal" >> /root/.bashrc && . /root/.bashrc

# Build cusignal
WORKDIR /root/
RUN git clone https://github.com/rapidsai/cusignal
#RUN export CUPY_NVCC_GENERATE_CODE="arch=compute_72,code=sm_72"
RUN /root/cusignal/build.sh

# Test on every run
# ENTRYPOINT [ "python", "import cupy; print(cupy.__version__)" ]