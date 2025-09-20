FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    supervisor \
    ffmpeg \
    curl \
    libasound2 \
    libasound2-data \
    libasound2-plugins \
    libpulse0 \
    alsa-utils \
    alsa-topology-conf \
    alsa-ucm-conf \
    pulseaudio-utils \
    && rm -rf /var/lib/apt/lists/*

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
    curl -L "https://github.com/bluenviron/mediamtx/releases/latest/download/mediamtx_v1.15.0_linux_${MEDIAMTX_ARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/mediamtx

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY mediamtx.yml /mediamtx.yml

RUN mkdir -p /var/log/supervisor

EXPOSE 8554 1935 8889 8189

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
