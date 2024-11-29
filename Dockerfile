# Distro vulnerable
FROM ubuntu:20.04

# Establecer el argumento de ambiente para evitar prompts interactivos
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
       gcc \
       g++ \
       make \
       python3 \
       python3-pip \
       gdb \
       vim \
       nano \
       build-essential \
       manpages-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Establecer Python3 como predeterminado
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

WORKDIR /heap_overflow_lab
COPY . .

CMD ["/bin/bash"]
