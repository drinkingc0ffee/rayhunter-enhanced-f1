FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install minimal base packages for initial setup
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create rayhunter user with sudo privileges
RUN useradd -m -s /bin/bash -u 1000 rayhunter && \
    echo "rayhunter:thehunted" | chpasswd && \
    usermod -aG sudo rayhunter && \
    echo "rayhunter ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "rayhunter user created with UID 1000"

# Copy the 3-step build scripts
COPY setup_ubuntu_ci.sh /home/rayhunter/
COPY fetch_source.sh /home/rayhunter/
COPY build_and_deploy.sh /home/rayhunter/

# Make scripts executable and set ownership
RUN chmod +x /home/rayhunter/*.sh && \
    chown rayhunter:rayhunter /home/rayhunter/*.sh && \
    echo "Scripts made executable and ownership set to rayhunter:rayhunter"

# Verify user setup before switching
RUN echo "Current user setup:" && \
    cat /etc/passwd | grep rayhunter && \
    ls -la /home/rayhunter/

# Switch to rayhunter user
USER rayhunter
WORKDIR /home/rayhunter

# Verify we're running as the correct user
RUN echo "Running as user: $(whoami)" && \
    echo "Home directory: $HOME" && \
    echo "User ID: $(id -u)" && \
    echo "Group ID: $(id -g)"

# Set up the build environment message
RUN echo "🔧 Rayhunter Enhanced Build Environment" > welcome.txt && \
    echo "=======================================" >> welcome.txt && \
    echo "" >> welcome.txt && \
    echo "📋 Simple 3-Step Build Process:" >> welcome.txt && \
    echo "1. ./setup_ubuntu_ci.sh     - Install toolchains & dependencies" >> welcome.txt && \
    echo "2. ./fetch_source.sh        - Download latest source code" >> welcome.txt && \
    echo "3. ./build_and_deploy.sh    - Build and install via adb" >> welcome.txt && \
    echo "" >> welcome.txt && \
    echo "🎯 Quick start: Run all steps with:" >> welcome.txt && \
    echo "   ./setup_ubuntu_ci.sh && ./fetch_source.sh && ./build_and_deploy.sh" >> welcome.txt && \
    echo "" >> welcome.txt

# Add welcome message to bashrc
RUN echo "" >> ~/.bashrc && \
    echo "# Rayhunter Enhanced Welcome" >> ~/.bashrc && \
    echo "cat ~/welcome.txt" >> ~/.bashrc && \
    echo "" >> ~/.bashrc

# Expose ports for web interface
EXPOSE 8080 8000

# Set default command to show instructions
CMD ["bash", "-c", "cat welcome.txt && exec bash"] 