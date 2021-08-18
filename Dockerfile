#
#
# Versions
ARG BASE_IMAGE=nvcr.io/nvidia/l4t-base:r32.6.1
FROM ${BASE_IMAGE}

#
#
# Apt setup
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get install -y --no-install-recommends\
    curl \
    git \
    make \
    g++ \
    ca-certificates 
    #&& rm -rf /var/lib/apt/lists/* \
    #&& apt-get clean


#
#
# Setup Environment
ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV CUDA_HOME="/usr/local/cuda:${CUDA_HOME}"
ENV CUDA_PATH="/usr/local/cuda:${CUDA_PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"
#ENV LLVM_CONFIG="/usr/bin/llvm-config-9"

ARG MAKEFLAGS=-j$(nproc)

#
#
# Non-root User
#ENV UNAME cusignal

#RUN useradd --uid 1000 --shell /bin/bash --user-group --create-home --groups sudo,video ${UNAME} \
#    && echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${UNAME} 

#RUN export UNAME=${UNAME} UID=1000 GID=1000 \
    #&& mkdir -p "/home/${UNAME}" \
    #&& echo "${UNAME}:x:${UID}:${GID}:${UNAME} User,,,:/home/${UNAME}:/bin/bash" >> /etc/passwd \
    #&& echo "${UNAME}:x:${UID}:" >> /etc/group \
    #&& mkdir -p /etc/sudoers.d \
    #&& echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${UNAME} \
    #&& chmod 0440 /etc/sudoers.d/${UNAME} \
    #&& chown ${UID}:${GID} -R /home/${UNAME} \
    #&& usermod -a -G video ${UNAME} \
    #&& usermod -a -G audio, root ${UNAME}

#ENV HOME /home/${UNAME}
#USER ${UNAME}
#WORKDIR ${HOME}
ENV HOME /root
WORKDIR ${HOME}

#
#
# Install miniforge
COPY ./Mambaforge-4.10.3-4-Linux-aarch64.sh ${HOME}
#RUN wget https://github.com/conda-forge/miniforge/releases/download/4.10.3-4/Mambaforge-4.10.3-4-Linux-aarch64.sh
RUN mkdir ${HOME}/.conda \
    && bash Mambaforge-4.10.3-4-Linux-aarch64.sh -b \
    && rm -f Mambaforge-4.10.3-4-Linux-aarch64.sh 
# Setup conda
ENV CONDA_NAME=cusignal
ENV PATH="${HOME}/mambaforge/bin:${PATH}"
RUN conda init bash
SHELL ["/bin/bash", "-c"]

#
#
# Install miniforge
COPY ./cusignal_jetson_base.yml ${HOME}
RUN conda env create -v -f cusignal_jetson_base.yml
ENV UNAME cusignal
RUN echo "source activate ${UNAME}" >> ${HOME}/.bashrc && source ${HOME}/.bashrc
ENV PATH="${HOME}/mambaforge/envs/${UNAME}bin:${PATH}"

#
#
# Copy Package repos
COPY ./cusignal/ ${HOME}/cusignal
COPY ./cupy/ ${HOME}/cupy

# choose GPU capability (save build time)
ENV CUPY_NVCC_GENERATE_CODE="arch=compute_72,code=sm_72"

RUN conda run -n ${UNAME} pip install -vvv ${HOME}/cupy/

#RUN bash -c "pip install cupy=9.3.0"
#ENV PATH=/home/cusignal/mambaforge/envs/cusignal/bin:${PATH}
#RUN conda info && /bin/bash && cd ~/cupy/ && pip --use-feature=in-tree-build install .


#RUN conda init bash
#RUN echo "source activate cusignal" >> ${HOME}/.bashrc && source ${HOME}/.bashrc
#RUN ["/home/cusignal/cusignal/build.sh",  "-v"]

# Install cusignal
#RUN git clone https://github.com/rapidsai/cusignal
#SHELL ["/bin/bash", "-c"]
#RUN ["conda", "activate", "cusignal"]
#RUN [ "conda", "run", "-n", "cusignal", "/bin/bash", "build.sh", "-v" ]
#COPY ./build_cusignal.sh ~/cusignal/build.sh
# Hakcing for gpu capability fix
#RUN ./cusignal/build.sh -v 


