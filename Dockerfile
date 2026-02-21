FROM        --platform=$TARGETOS/$TARGETARCH ubuntu:22.04

LABEL      author="RelixOfficial" maintainer="dzakyadis9@gmail.com" description="Powerful Docker Image to run Node.js applications with PM2 and supports Android SDK and supports 7 essential utility Programming Languages."

ARG DEBIAN_FRONTEND=noninteractive

# add container user and set stop signal
RUN useradd -m -d /home/container container
STOPSIGNAL SIGINT

# Versi stabil (LTS) untuk tiap bahasa
ARG GO_VERSION=1.23.10
ARG PYTHON_VERSION=3.12.11
ARG PHP_VERSION=8.2.20
ARG PERL_VERSION=5.38.4
ARG JAVA_VERSION=21.0.7+6
ARG DOTNET_VERSION=8.0.301
ARG RUBY_VERSION=3.3.8

# Install base dependencies via apt (keperluan build)
RUN apt-get update && apt-get -y upgrade && apt-get -y install \
    ffmpeg \
    iproute2 \
    git \
    sqlite3 \
    libsqlite3-dev \
    elixir \
    webp \
    neofetch \
    imagemagick \
    ssh \
    sudo \
    wget \
    ca-certificates \
    dnsutils \
    tzdata \
    zip \
    tar \
    curl \
    build-essential \
    libtool \
    iputils-ping \
    libnss3 \
    tini \
    unzip \
    xz-utils \
    pkg-config \
    libssl-dev \
    zlib1g-dev \
    libreadline-dev \
    libbz2-dev \
    liblzma-dev \
    libncurses-dev \
    libgdbm-dev \
    libffi-dev \
    libmpdec-dev \
    libicu-dev \
    libpq-dev \
    cmake \
    autoconf \
    libxml2-dev \
    libyaml-dev \
    libjpeg-dev \
    libpng-dev \
    gnupg \
    lsb-release \
    software-properties-common

# ========== Caching Downloads via ADD ==========
# Python
ADD https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz /tmp/Python-${PYTHON_VERSION}.tgz
# Go
ADD https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz /tmp/go${GO_VERSION}.linux-amd64.tar.gz
# PHP
ADD https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz /tmp/php-${PHP_VERSION}.tgz
# Perl
ADD https://www.cpan.org/src/5.0/perl-${PERL_VERSION}.tar.gz /tmp/perl-${PERL_VERSION}.tgz
# Java (Temurin/OpenJDK 21 LTS)
ADD https://github.com/adoptium/temurin21-binaries/releases/download/jdk-${JAVA_VERSION}/OpenJDK21U-jdk_x64_linux_hotspot_21.0.7_6.tar.gz /tmp/java-${JAVA_VERSION}.tgz
# Ruby
ADD https://cache.ruby-lang.org/pub/ruby/3.3/ruby-${RUBY_VERSION}.tar.gz /tmp/ruby-${RUBY_VERSION}.tgz

# ========== Install bahasa dari sumber resmi (manual build) ==========

# JAVA
WORKDIR /opt
RUN tar -xzf /tmp/java-${JAVA_VERSION}.tgz && mv jdk-* java && \
    rm /tmp/java-${JAVA_VERSION}.tgz
ENV JAVA_HOME="/opt/java"
ENV PATH="$JAVA_HOME/bin:$PATH"

# .NET
WORKDIR /tmp/dotnet
RUN curl -fsSL https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh -o dotnet-install.sh && \
    chmod +x dotnet-install.sh && \
    ./dotnet-install.sh --version $DOTNET_VERSION --install-dir /usr/share/dotnet && \
    rm -rf /tmp/dotnet
ENV DOTNET_ROOT="/usr/share/dotnet"
ENV PATH="$DOTNET_ROOT:$PATH"

# GO
RUN tar -C /usr/local -xzf /tmp/go${GO_VERSION}.linux-amd64.tar.gz && \
    rm /tmp/go${GO_VERSION}.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:$PATH"

# RUST
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"

# PERL
WORKDIR /tmp/perl
RUN tar -xzf /tmp/perl-${PERL_VERSION}.tgz && \
    cd perl-${PERL_VERSION} && \
    ./Configure -des -Dprefix=/usr/local && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/perl

# PHP
WORKDIR /tmp/php
RUN tar -xzf /tmp/php-${PHP_VERSION}.tgz && \
    cd php-${PHP_VERSION} && \
    ./configure --disable-cgi --enable-cli --with-openssl --with-zlib && \
    make -j$(nproc) && make install && \
    rm -rf /tmp/php

# RUBY
WORKDIR /tmp/ruby
RUN tar -xzf /tmp/ruby-${RUBY_VERSION}.tgz && \
    cd ruby-${RUBY_VERSION} && \
    ./configure && make -j$(nproc) && make install && \
    rm -rf /tmp/ruby

# PYTHON
WORKDIR /tmp/python
RUN tar -xzf /tmp/Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && make altinstall && \
    ln -s /usr/local/bin/python3.12 /usr/local/bin/python3 && \
    ln -s /usr/local/bin/python3 /usr/local/bin/python && \
    ln -s /usr/local/bin/pip3.12 /usr/local/bin/pip3 && \
    ln -s /usr/local/bin/pip3 /usr/local/bin/pip && \
    rm -rf /tmp/python


# ---- 4) Setup Android SDK ----
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_TOOLS_VERSION=11076708
ENV ANDROID_ONLINE=true

RUN arch="$(uname -m)" && if [ "$arch" = "x86_64" ] || [ "$arch" = "amd64" ]; then \
  apt-get update && apt-get install -y --no-install-recommends \
    lib32stdc++6 lib32z1 libbz2-1.0:i386 libc6:i386 libncurses5:i386 || true && \
  rm -rf /var/lib/apt/lists/* && \
  mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
  wget -q "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip" -O /tmp/cmdline-tools.zip && \
  unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
  mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
  rm /tmp/cmdline-tools.zip && \
  yes | ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses > /dev/null && \
  ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager --sdk_root=${ANDROID_SDK_ROOT} \
    "platform-tools" "platforms;android-34" "build-tools;34.0.0" \
    "platforms;android-31" "build-tools;30.0.3" \
    "platforms;android-35" "build-tools;35.0.0" > /dev/null ; \
else \
  echo "Skipping Android SDK installation: unsupported arch"; \
fi


# ---- 5) Install Gradle (fallback) ----
ENV GRADLE_VERSION=8.7
RUN wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -O /tmp/gradle.zip \
    && unzip -q /tmp/gradle.zip -d /opt \
    && ln -s /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/local/bin/gradle \
    && rm /tmp/gradle.zip

# ---- 6) Install Node.js & PM2 ----
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s $(which node) /usr/local/bin/node \
    && ln -s $(which npm)  /usr/local/bin/npm \
    && npm install -g pm2
    
    
# Install sqlmap dari GitHub dan buat executable global
RUN git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git /usr/share/sqlmap && \
    ln -s /usr/share/sqlmap/sqlmap.py /usr/bin/sqlmap && \
    chmod +x /usr/bin/sqlmap /usr/share/sqlmap/sqlmap.py


# ---- 8) PATH & Permissions ----
ENV PATH="/usr/local/bin:/opt/gradle-${GRADLE_VERSION}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# Pastikan direktori SDK dan home dimiliki oleh user container 
RUN mkdir -p ${ANDROID_SDK_ROOT} ${ANDROID_HOME} && \
    chown -R container:container /home/container ${ANDROID_SDK_ROOT} ${ANDROID_HOME}
RUN chmod 755 /home/container

# Node.js & PM2
RUN npm install --global npm@latest typescript ts-node @types/node
RUN npm install -g pm2

# pnpm
RUN npm install -g corepack && corepack enable && corepack prepare pnpm@latest --activate


USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY --chown=container:container ./../entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]