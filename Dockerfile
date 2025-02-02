# 使用 Debian 最新版本作为基础镜像
FROM debian:latest

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    ROOT_PASSWORD=""

# 安装必要的包
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    openssh-server \
    iptables \
    wget \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 下载并安装 ttyd
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -O /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# 配置 SSH
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 创建启动脚本
RUN echo '#!/bin/bash\n\
# 设置 root 密码\n\
if [ ! -z "$ROOT_PASSWORD" ]; then\n\
    echo "root:$ROOT_PASSWORD" | chpasswd\n\
fi\n\
\n\
# 启动 SSH 服务\n\
/usr/sbin/sshd\n\
\n\
# 启动 ttyd\n\
/usr/local/bin/ttyd bash &\n\
\n\
# 保持容器运行\n\
tail -f /dev/null' > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

# 暴露 SSH 和 ttyd 端口
EXPOSE 22 7681

# 设置入口点
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
