FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# System toolchain + MariaDB 10.11 (matches the origin of the committed SQL dumps
# and satisfies Django 6.x's MariaDB 10.5+ requirement). mysqlclient needs
# default-libmysqlclient-dev + build tools to compile.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        sudo \
        tzdata \
        build-essential \
        pkg-config \
        python3 \
        python3-dev \
        python3-venv \
        python3-pip \
        default-libmysqlclient-dev \
        mariadb-server \
        mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# ubuntu:24.04 ships a default "ubuntu" user (uid 1000). Grant passwordless sudo
# so install/start scripts can manage the local MariaDB service.
RUN usermod -aG sudo ubuntu \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-ubuntu \
    && chmod 0440 /etc/sudoers.d/90-ubuntu

USER ubuntu
WORKDIR /home/ubuntu
