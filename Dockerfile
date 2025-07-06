# Containerfile
# Or your preferred Linux distribution (e.g., fedora:39, debian:stable)
FROM ubuntu:24.10
LABEL description="Yazelix testing environment with common dependencies"

# Set a non-root user (optional but good practice for interactive containers)
ARG USERNAME=nacho
ARG UID=1001
ARG GID=1001

RUN groupadd --gid $GID $USERNAME \
    && useradd --uid $UID --gid $GID -m $USERNAME \
    && apt-get update && apt-get install -y \
        git \
        curl \
        wget \
        build-essential \
        libssl-dev \
        pkg-config \
        ca-certificates \
        # General utilities you might need for debugging/testing
        sudo \
        iputils-ping \
        net-tools \
        # Required for Nushell and other Rust-based tools
        rustc \
        cargo \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Switch to the new user
USER $USERNAME
WORKDIR /home/$USERNAME

# Install Nushell (using rustup as recommended by Nushell)
# This might take a while
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal \
    && echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> $HOME/.profile \
    && echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> $HOME/.bashrc \
    && /bin/bash -c "source $HOME/.cargo/env && cargo install nu_plugin_query" \
    && /bin/bash -c "source $HOME/.cargo/env && cargo install nu"

# Install Zellij (assuming a recent static binary is available)
# Check Zellij releases for the latest version
# Check https://github.com/zellij-org/zellij/releases
ENV ZELLIJ_VERSION="0.42.2"
USER root
RUN curl -LO "https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz" \
    && tar -xzf zellij-x86_64-unknown-linux-musl.tar.gz \
    && mv zellij /usr/local/bin/zellij \
    && rm zellij-x86_64-unknown-linux-musl.tar.gz

# Install Helix (assuming a recent static binary is available)
# Check Helix releases for the latest version
# Check https://github.com/helix-editor/helix/releases
ENV HELIX_VERSION="25.01.1"
RUN curl -LO "https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-x86_64-linux.tar.xz" \
    && tar -xf helix-${HELIX_VERSION}-x86_64-linux.tar.xz \
    && mv helix-${HELIX_VERSION}-x86_64-linux/hx /usr/local/bin/hx \
    && rm -rf helix-${HELIX_VERSION}-x86_64-linux.tar.xz helix-${HELIX_VERSION}-x86_64-linux/

# Install Yazi (assuming a recent static binary is available)
# Check Yazi releases for the latest version
# Check https://github.com/sxycode/yazi/releases
ENV YAZI_VERSION="25.5.31"
RUN curl -LO "https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-musl.zip" \
    && unzip yazi-x86_64-unknown-linux-musl.zip \
    && mv yazi-x86_64-unknown-linux-musl/yazi /usr/local/bin/yazi \
    && rm -rf yazi-x86_64-unknown-linux-musl.zip yazi-x86_64-unknown-linux-musl/

# Download gostty
RUN wget https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.1.3-0-ppa2/ghostty_1.1.3-0.ppa2_amd64_25.04.deb \
   && sudo apt install -y gdebi-core \
   && sudo gdebi ./ghostty_*.deb

USER $USERNAME

# Clone Yazelix configuration
RUN git clone https://github.com/luccahuguet/yazelix.git /home/$USERNAME/.config/yazelix \
    && ln -s /home/$USERNAME/.config/yazelix/zellij /home/$USERNAME/.config/zellij \
    && ln -s /home/$USERNAME/.config/yazelix/yazi /home/$USERNAME/.config/yazi \
    && ln -s /home/$USERNAME/.config/yazelix/helix /home/$USERNAME/.config/helix \
    && mkdir -p /home/$USERNAME/.config/nushell \
    && mkdir -p /home/$USERNAME/.config/ghostty \
    && cp ~/.config/yazelix/terminal_configs/ghostty/config ~/.config/ghostty/config
# Set default command to run Nushell
CMD ["nu"]
