# Use Debian-based docker:dind
FROM debian:latest

# Switch to root for installation
USER root

# Install OpenSSH server and required packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openssh-server \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/sshd

# Configure SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 创建设置密码的脚本
RUN echo '#!/bin/sh\n\
if [ ! -z "$ROOT_PASSWORD" ]; then\n\
    echo "root:$ROOT_PASSWORD" | chpasswd\n\
fi\n\
/usr/sbin/sshd -D &' > /usr/local/bin/start-ssh.sh && \
    chmod +x /usr/local/bin/start-ssh.sh

# 在 /etc/rc.local 中添加启动 SSH 的命令
RUN echo '#!/bin/sh\n/usr/local/bin/start-ssh.sh' > /etc/rc.local && \
    chmod +x /etc/rc.local

# Expose SSH port
EXPOSE 22

# 声明环境变量
ENV ROOT_PASSWORD=""
