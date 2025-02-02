# 使用 Debian 最新版本作为基础镜像
FROM debian:latest

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    ROOT_PASSWORD=""

# 安装必要的包，包括 systemd 和 wget
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    systemd \
    systemd-sysv \
    openssh-server \
    wget \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/dpkg/info/*.postinst

# 下载并安装 ttyd
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -O /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# 配置 systemd
RUN systemctl set-default multi-user.target \
    && systemctl mask -- \
      dev-hugepages.mount \
      sys-fs-fuse-connections.mount \
      sys-kernel-config.mount \
      sys-kernel-debug.mount \
      tmp.mount \
    && systemctl mask -- \
      systemd-tmpfiles-setup.service \
      systemd-update-utmp.service \
      systemd-udevd.service \
      systemd-random-seed.service

# 配置 SSH
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 创建 SSH 密码设置脚本
RUN echo '#!/bin/bash\n\
if [ ! -z "$ROOT_PASSWORD" ]; then\n\
    echo "root:$ROOT_PASSWORD" | chpasswd\n\
fi' > /usr/local/bin/set-ssh-password.sh \
    && chmod +x /usr/local/bin/set-ssh-password.sh

# 创建 systemd 服务来设置 SSH 密码
RUN echo '[Unit]\n\
Description=Set SSH root password\n\
Before=ssh.service\n\
\n\
[Service]\n\
Type=oneshot\n\
ExecStart=/usr/local/bin/set-ssh-password.sh\n\
RemainAfterExit=yes\n\
\n\
[Install]\n\
WantedBy=multi-user.target' > /etc/systemd/system/set-ssh-password.service

# 创建 ttyd 服务
RUN echo '[Unit]\n\
Description=TTYD Web Terminal Service\n\
After=network.target\n\
\n\
[Service]\n\
Type=simple\n\
ExecStart=/usr/local/bin/ttyd bash\n\
Restart=always\n\
\n\
[Install]\n\
WantedBy=multi-user.target' > /etc/systemd/system/ttyd.service

# 启用服务
RUN systemctl enable set-ssh-password.service \
    && systemctl enable ssh \
    && systemctl enable ttyd.service

# 暴露 SSH 和 ttyd 端口
EXPOSE 22 7681

# 清理不需要的系统服务
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-update-utmp*

# 设置 systemd 作为入口点
ENTRYPOINT ["/lib/systemd/systemd"]
