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
    locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#Cria um usuário hadoop, senha e adiciona ao sudoeres
RUN echo "root:default" | chpasswd && \
    passwd -e root && \
    useradd -m -d /home/hadoop -s /bin/bash hadoop && \
    echo "hadoop:default" | chpasswd && \
    adduser hadoop sudo && \
    passwd -e hadoop && \
    echo 'hadoop ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/hadoop

#Define o diretório de trabalho
WORKDIR /home/hadoop

#Copia o script bash para o container
COPY ./automatization-cluster.sh /home/hadoop/
COPY ./script-database-zabbix.sh /usr/local/bin

#Instala o jdk
RUN wget https://download.oracle.com/java/22/latest/jdk-22_linux-x64_bin.deb && \
    wget https://repo.maven.apache.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/1.0.1/jmx_prometheus_javaagent-1.0.1.jar && \
    dpkg -i jdk-22_linux-x64_bin.deb && \
    rm jdk-22_linux-x64_bin.deb


# Gera uma chave SSH, configura o arquivo authorized_keys e configura o arquivo /etc/ssh/sshd_config
RUN echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config && \
    mkdir -p /home/hadoop/.ssh && \
    ssh-keygen -t rsa -b 4096 -f /home/hadoop/.ssh/id_rsa -N "" && \
    chown -R hadoop:hadoop /home/hadoop/.ssh

#Instala o hadoop e altera as permissões da pasta hadoop
RUN wget http://ftp.unicamp.br/pub/apache/hadoop/common/stable/hadoop-3.4.0.tar.gz && \
    tar -xzf hadoop-3.4.0.tar.gz && \
    mv hadoop-3.4.0 hadoop && \
    rm -r hadoop-3.4.0.tar.gz && \
    chown -R hadoop:hadoop /home/hadoop/hadoop && \
    chown -R hadoop:hadoop /home/hadoop/automatization-cluster.sh
    
#instalando Zabbix
RUN wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-2+ubuntu22.04_all.deb && \
    dpkg -i zabbix-release_7.0-2+ubuntu22.04_all.deb && \
    apt update && \
    apt install -y --no-install-recommends zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Comando padrão para executar quando o contêiner for iniciado
CMD [ "/bin/bash" ]
