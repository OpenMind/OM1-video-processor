FROM ghcr.io/astral-sh/uv:latest AS uvbin

FROM nvcr.io/nvidia/l4t-jetpack:r36.4.0

SHELL ["/bin/bash","-lc"]
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONNOUSERSITE=1 \
    CUDA_ROOT=/usr/local/cuda

ENV PATH="${CUDA_ROOT}/bin:${PATH}" \
    LD_LIBRARY_PATH="/usr/lib/aarch64-linux-gnu:/usr/lib/aarch64-linux-gnu/tegra:${CUDA_ROOT}/lib64:${LD_LIBRARY_PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
      git \
      ffmpeg \
      portaudio19-dev \
      libasound2-dev \
      libv4l-dev \
      libasound2 \
      libasound2-data \
      libasound2-plugins \
      libpulse0 \
      alsa-utils \
      alsa-topology-conf \
      alsa-ucm-conf \
      pulseaudio-utils \
      build-essential \
      cmake \
      pkg-config \
      curl \
      ca-certificates \
      python3-dev \
      python3-venv \
      python3-pip \
      libssl-dev \
      libnvinfer-bin \
      python3-libnvinfer \
      python3-libnvinfer-dev \
      libturbojpeg \
      libjpeg-turbo8-dev \
      supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=uvbin /uv /uvx /usr/local/bin/

RUN mkdir -p /etc/alsa && \
    ln -snf /usr/share/alsa/alsa.conf.d /etc/alsa/conf.d

RUN printf '%s\n' \
  'pcm.!default { type pulse }' \
  'ctl.!default { type pulse }' \
  > /etc/asound.conf

RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        MEDIAMTX_ARCH="arm64"; \
    elif [ "$ARCH" = "x86_64" ]; then \
        MEDIAMTX_ARCH="amd64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    echo "Downloading MediaMTX for architecture: $MEDIAMTX_ARCH" && \
    curl -L "https://github.com/bluenviron/mediamtx/releases/download/v1.15.1/mediamtx_v1.15.1_linux_${MEDIAMTX_ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/mediamtx

COPY video_processor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY video_processor/mediamtx.yml /mediamtx.yml

RUN mkdir -p /var/log/supervisor

RUN mkdir -p /app/om1_video_processor
WORKDIR /app/om1_video_processor

COPY . .

RUN python -m pip install -U pip setuptools wheel packaging \
    "numpy>2.1.0" "pytools>=2024.1" "pybind11>=2.10" && \
    export NUMPY_INC="$(python -c 'import numpy,sys;sys.stdout.write(numpy.get_include())')" && \
    export CFLAGS="${CFLAGS:-} -I${CUDA_ROOT}/include -I${NUMPY_INC}" && \
    export CXXFLAGS="${CXXFLAGS:-} -I${CUDA_ROOT}/include" && \
    export LDFLAGS="${LDFLAGS:-} -L${CUDA_ROOT}/lib64" && \
    python -m pip uninstall -y pycuda || true && \
    python -m pip install --no-cache-dir --no-binary=:all: --no-build-isolation "pycuda>=2024.1"

RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'set -e' >> /entrypoint.sh && \
    echo 'echo ">> Setting up Python environment..."' >> /entrypoint.sh && \
    echo 'if [ ! -f "/app/om1_video_processor/.venv/bin/activate" ]; then' >> /entrypoint.sh && \
    echo '  echo ">> Creating virtualenv and installing deps..."' >> /entrypoint.sh && \
    echo '  uv venv --system-site-packages /app/om1_video_processor/.venv' >> /entrypoint.sh && \
    echo '  uv sync --all-extras' >> /entrypoint.sh && \
    echo 'else' >> /entrypoint.sh && \
    echo '  echo ">> Reusing existing virtualenv, syncing deps..."' >> /entrypoint.sh && \
    echo '  uv sync --all-extras' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    echo 'echo ">> Environment setup complete, starting supervisord..."' >> /entrypoint.sh && \
    echo 'exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
