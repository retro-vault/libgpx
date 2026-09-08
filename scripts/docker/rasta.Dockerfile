FROM ubuntu:24.04
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    --no-install-recommends build-essential cmake pkg-config libsdl2-dev \
    python3 python3-pil git ca-certificates xvfb xauth && rm -rf /var/lib/apt/lists/*
WORKDIR /work
