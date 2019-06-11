ARG cuda_version=10.0
ARG cudnn_version=7
FROM nvidia/cuda:${cuda_version}-cudnn${cudnn_version}-devel

LABEL maintainer="Ben Evans <ben.d.evans@gmail.com>"

# ENTRYPOINT [ "/bin/bash", "-c" ]
# Needed for string substitution
SHELL ["/bin/bash", "-c"]

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
      bzip2 \
      build-essential \
      # g++ \
      git \
      graphviz \
      libgl1-mesa-glx \
      libhdf5-dev \
      locales \
      openmpi-bin \
      wget && \
    rm -rf /var/lib/apt/lists/*

RUN echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Configure environment
ARG NB_UID=1000
ARG NB_GID=100
ARG NB_USER=thedude

ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_GB.UTF-8 \
    LANG=en_GB.UTF-8 \
    LANGUAGE=en_GB.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

# Install conda
ARG MINICONDA_VERSION=4.6.14
ARG MINCONDA_MD5=718259965f234088d785cad1fbd7de03

ENV MINICONDA_VERSION=$MINICONDA_VERSION \
    MINCONDA_MD5=$MINCONDA_MD5
RUN wget --quiet --no-check-certificate https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "${MINCONDA_MD5} *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash /Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo export PATH=$CONDA_DIR/bin:'$PATH' > /etc/profile.d/conda.sh

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

RUN useradd -m -s /bin/bash -N -u $NB_UID -g $NB_GID $NB_USER && \
    chown $NB_USER $CONDA_DIR -R && \
    mkdir -p /src && \
    chown $NB_USER /src && \
    mkdir -p /work/{src,data,results,logs} && \
    chown -R $NB_USER /work

# Install Python packages and keras
USER $NB_USER

ARG python_version=3.6

RUN conda config --append channels conda-forge
RUN conda config --append channels pytorch
RUN conda install -y python=${python_version}
RUN pip install --upgrade pip
# RUN pip install --upgrade pip && \
#     pip install \
#       sklearn_pandas \
#       # tensorflow-gpu \
#       cntk-gpu
RUN conda install --quiet --yes \
      imagemagick \
      bcolz \
      h5py \
      joblib \
      matplotlib \
      bokeh \
      selenium \
      phantomjs \
      networkx \
      sphinx \
      seaborn \
      mkl \
      nose \
      Pillow \
      pandas \
      pydot \
      pygpu \
      pyyaml \
      scikit-learn \
      scikit-image \
      opencv \
      six \
      # theano \
      mkdocs \
      tqdm \
      tensorflow-gpu \
      keras-gpu \
      # git \
      setuptools \
      cmake \
      cffi \
      typing \
      pytorch \
      ignite \
      torchvision \
      # "cudatoolkit>=${cuda_version}" \
      'cudatoolkit>=10.0' \
      magma-cuda100 \
      tensorboard \
      nodejs \
      'notebook=5.7.8' \
      'jupyterhub=1.0.0' \
      'jupyterlab=0.35.6' \
      ipywidgets \
      widgetsnbextension \
      nbdime \
      jupyterlab-git && \
      conda clean --all -f -y && \
      jupyter labextension install @jupyterlab/hub-extension@^0.12.0 && \
      jupyter labextension install @jupyterlab/google-drive && \
      jupyter labextension install @jupyterlab/git && \
      jupyter serverextension enable --py jupyterlab_git && \
      jupyter labextension install @jupyterlab/github && \
      jupyter labextension install jupyterlab-drawio && \
      jupyter labextension install jupyterlab_bokeh@0.6.3 && \
      jupyter labextension install @jupyter-widgets/jupyterlab-manager && \
      npm cache clean --force && \
      jupyter notebook --generate-config && \
      rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
      rm -rf /home/$NB_USER/.cache/yarn
#      && \
# RUN git clone git://github.com/keras-team/keras.git /src && pip install -e /src[tests] && \
#     pip install git+git://github.com/keras-team/keras.git && \
#     conda clean -yt

RUN nbdime config-git --enable --global
# Use the environment.yml to create the conda environment.
# https://fmgdata.kinja.com/using-docker-with-conda-environments-1790901398
# COPY environment.yml /tmp/environment.yml
# RUN [ "conda", "update", "conda", "-y" ]
# RUN [ "conda", "update", "--all", "-y" ]

# RUN [ -s /tmp/environment.yml ] && conda env update -n root -f /tmp/environment.yml

# COPY theanorc /home/thedude/.theanorc

# ENV LC_ALL=C.UTF-8
# ENV LANG=C.UTF-8

ENV PYTHONPATH='/src/:/work/src/:$PYTHONPATH'

# WORKDIR $HOME
# VOLUME $HOME
WORKDIR /work
VOLUME /work

EXPOSE 6006 8888

CMD ["jupyter", "lab", "--port=8888", "--ip=0.0.0.0"]
