FROM nvcr.io/nvidia/l4t-base:r32.6.1
ENV DEBIAN_FRONTEND noninteractive
ARG MAKEFLAGS=-j$(nproc) 

# Fetch
RUN apt-get update && apt upgrade -yf 
RUN apt-get install -y sudo wget git ca-certificates libssl1.1 build-essential g++
RUN update-ca-certificates

# Deploy Conda
ENV UNAME cusignal
ENV HOME /home/${UNAME}
ENV PATH="${HOME}/mambaforge/bin:${PATH}"
ENV PATH="/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"
ENV CUDA_HOME="/usr/local/cuda"

RUN export UNAME=$UNAME UID=1000 GID=1000 \
    && mkdir -p "/home/${UNAME}" \
    && echo "${UNAME}:x:${UID}:${GID}:${UNAME} User,,,:/home/${UNAME}:/bin/bash" >> /etc/passwd \
    && echo "${UNAME}:x:${UID}:" >> /etc/group \
    && mkdir -p /etc/sudoers.d \
    && echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${UNAME} \
    && chmod 0440 /etc/sudoers.d/${UNAME} \
    && chown ${UID}:${GID} -R /home/${UNAME} \
    && usermod -a -G audio,root ${UNAME}


USER $UNAME
WORKDIR ${HOME}/

COPY ./Mambaforge-4.10.3-4-Linux-aarch64.sh ${HOME}
#RUN wget https://github.com/conda-forge/miniforge/releases/download/4.10.3-4/Mambaforge-4.10.3-4-Linux-aarch64.sh
RUN mkdir ${HOME}/.conda \
    && bash Mambaforge-4.10.3-4-Linux-aarch64.sh -b \
    && rm -f Mambaforge-4.10.3-4-Linux-aarch64.sh

# Prepare cusignal
COPY ./cusignal_jetson_base.yml ${HOME}
RUN conda env create --file cusignal_jetson_base.yml
RUN conda init bash
#SHELL ["/bin/bash", "-c"]
#RUN echo ". activate cusignal" >> ${HOME}/.bashrc && . ${HOME}/.bashrc
RUN echo "source activate cusignal" >> ${HOME}/.bashrc

#RUN git clone https://github.com/rapidsai/cusignal
#RUN pip install cupy --no-cache-dir -vvv

COPY ./cusignal ${HOME}/cusignal/
#COPY ./build_cusignal.sh ~/cusignal/build.sh
# Hakcing for gpu capability fix
ENV PATH=/home/cusignal/mambaforge/envs/cusignal/bin:${PATH}
RUN ./cusignal/build.sh -v 


