# Usa Ubuntu 22.04 como imagen base
FROM ubuntu:22.04
	
# Informa o autor do container
LABEL maintainer="ericjesus403@gmail.com"

ENV DEBIAN_FRONTEND=noninteractive

# Atualiza os pacotes e instala alguns programas essenciais
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    sudo \
    curl \
    vim \
    git \
    openssh-server \
    openssh-client \
    build-essential \
    iputils-ping \
    mysql-server \
    software-properties-common \
    wget \
    openjdk-8-jdk \
    locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "root:default" | chpasswd && \
    echo 'root ALL=(ALL) NOPASSWD: /usr/bin/mysql, /usr/bin/zcat, /usr/sbin/service' >> /etc/sudoers && \
    useradd -m -d /home/hadoop -s /bin/bash hadoop && \
    echo "hadoop:default" | chpasswd && \
    adduser hadoop sudo && \
    echo 'hadoop ALL=(ALL) NOPASSWD: /usr/bin/mysql, /usr/bin/zcat, /usr/sbin/service' >> /etc/sudoers

#Define o diretório de trabalho
WORKDIR /home/hadoop

#Copia o script bash para o container
COPY ./automatization-cluster.sh /home/hadoop/
COPY ./script-database-zabbix.sh /usr/local/bin
COPY ./script-host.sh /home/hadoop/
COPY ./verification-cluster.sh /home/hadoop/
COPY ./request-script.sh /home/hadoop

# Gera uma chave SSH, configura o arquivo authorized_keys e configura o arquivo /etc/ssh/sshd_config
RUN echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config && \
    mkdir -p /home/hadoop/.ssh && \
    ssh-keygen -t rsa -b 4096 -f /home/hadoop/.ssh/id_rsa -N "" && \
    chown -R hadoop:hadoop /home/hadoop/.ssh && \
    chmod +x /home/hadoop/verification-cluster.sh && \
    chmod +x /home/hadoop/request-script.sh && \
    wget http://ftp.unicamp.br/pub/apache/hadoop/common/stable/hadoop-3.4.0.tar.gz && \
    tar -xzf hadoop-3.4.0.tar.gz && \
    mv hadoop-3.4.0 hadoop && \
    rm -r hadoop-3.4.0.tar.gz && \
    chown -R hadoop:hadoop /home/hadoop/hadoop && \
    chown -R hadoop:hadoop /home/hadoop/automatization-cluster.sh && \
    chown -R hadoop:hadoop /home/hadoop/script-host.sh && \
    wget https://dlcdn.apache.org/spark/spark-3.5.3/spark-3.5.3-bin-hadoop3.tgz && \
    tar -xzvf spark-3.5.3-bin-hadoop3.tgz && \
    mv spark-3.5.3-bin-hadoop3 spark && \
    rm -r spark-3.5.3-bin-hadoop3.tgz && \
    wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu22.04_all.deb && \
    dpkg -i zabbix-release_7.0-2+ubuntu22.04_all.deb && \
    apt update && \
    apt install -y --no-install-recommends zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent2 && \
    rm -r zabbix-release_7.0-2+ubuntu22.04_all.deb && \
    apt install -y adduser libfontconfig1 musl && \
    wget https://dl.grafana.com/enterprise/release/grafana-enterprise_11.2.0_amd64.deb && \
    dpkg -i grafana-enterprise_11.2.0_amd64.deb && \
    rm -r grafana-enterprise_11.2.0_amd64.deb

# Comando padrão para executar quando o contêiner for iniciado
ENTRYPOINT [ "./script-host.sh"]
