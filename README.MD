Claro, aqui está uma sugestão de `readme.md` aprimorado, baseado no conteúdo que você forneceu.

-----

# 🚀 Cluster Hadoop com Monitoramento via Docker

Este projeto oferece uma solução completa para a criação de um ambiente **Hadoop distribuído**, totalmente containerizado com **Docker**. Inclui ferramentas de monitoramento como **Zabbix** e **Grafana**, gerenciamento de containers com **Portainer** e conectividade de rede virtual via **ZeroTier**, permitindo a simulação de clusters tanto locais quanto remotos.

-----

## 📦 Requisitos

Antes de começar, garanta que seu ambiente atenda aos seguintes pré-requisitos:

  - **Sistema Operacional:** Linux (testado em Ubuntu/Debian)
  - **Containerização:** Docker e Docker Compose
  - **Rede Virtual (Opcional):** [ZeroTier](https://www.zerotier.com/) para conectar máquinas em redes distintas.

-----

## 🛠️ Etapas de Configuração

Siga os passos abaixo para preparar seu ambiente e configurar o cluster.

### 🧭 Etapa 1 — Instalar e Configurar ZeroTier (Opcional)

Utilize o ZeroTier para criar uma rede virtual privada e segura, conectando máquinas como se estivessem na mesma rede local.

1.  **Instale o ZeroTier em cada máquina:**

    ```bash
    curl -s https://install.zerotier.com | sudo bash
    ```

2.  **Crie uma Rede Virtual:**

      - Acesse o painel [my.zerotier.com](https://my.zerotier.com).
      - Crie uma nova rede e anote o **Network ID**.

3.  **Conecte cada máquina à rede:**

    ```bash
    sudo zerotier-cli join <SEU_NETWORK_ID>
    ```

4.  **Autorize os Dispositivos:**

      - Volte ao painel do ZeroTier.
      - Na seção "Members", autorize cada máquina que se conectou à sua rede. Anote os IPs atribuídos a elas.

### ✍️ Etapa 2 — Editar o Arquivo `/etc/hosts`

Em **todas as máquinas** que farão parte do cluster (master e slaves), adicione os IPs (da sua rede local ou da rede ZeroTier) e os respectivos hostnames.

1.  Abra o arquivo `hosts` para edição:

    ```bash
    sudo nano /etc/hosts
    ```

2.  Adicione as entradas, mapeando o IP de cada nó ao seu nome.

    ```properties
    # Exemplo
    10.147.17.1    master
    10.147.17.2    slave1
    10.147.17.3    slave2
    ```

### 🧰 Etapa 3 — Clonar o Projeto e Construir a Imagem Docker

1.  Clone o repositório do projeto:

    ```bash
    git clone https://github.com/ericsanto/cluster-hadoop.git
    ```

2.  Navegue até o diretório do projeto:

    ```bash
    cd cluster-hadoop
    ```

3.  Construa a imagem Docker personalizada para o Hadoop:

    ```bash
    sudo docker build -t hadoop .
    ```

-----

## ▶️ Execução e Operação do Cluster

Com o ambiente configurado, siga estes passos para iniciar e gerenciar o cluster.

### 🐳 Etapa 4 — Executar o Container Hadoop

Execute este comando em **todas as máquinas** (master e slaves) para iniciar o container em modo de rede host.

```bash
sudo docker run -it --network host hadoop
```

### 🔄 Etapa 5 — Alternar para o Usuário `hadoop`

Dentro do container, todos os comandos específicos do Hadoop devem ser executados pelo usuário `hadoop`.

```bash
su hadoop
```

### ⚙️ Etapa 6 — Automatizar a Configuração dos Nós

Utilize o script de automação para configurar cada nó de acordo com sua função (master ou slave).

1.  **No nó Master:**

    ```bash
    # Exemplo: 1 slave no cluster e 5000 MB de RAM para o Hadoop
    ./automatization-cluster.sh --config master --slaves 1 --memory-ram 5000
    ```

2.  **Em cada nó Slave:**

    ```bash
    # A configuração de memória deve ser a mesma em todos os nós
    ./automatization-cluster.sh --config slave --slaves 1 --memory-ram 5000
    ```

### 🧱 Etapa 7 — Formatar o NameNode (Apenas no Master)

**Atenção:** Este comando deve ser executado **uma única vez** e **somente no nó master**. Ele inicializa o sistema de arquivos do HDFS.

```bash
hdfs namenode -format
```

### ▶️ Etapa 8 — Iniciar os Serviços do Hadoop (Apenas no Master)

Use o script `start-all.sh` no nó master para iniciar todos os daemons do Hadoop (NameNode, DataNodes, ResourceManager, etc.).

```bash
$HADOOP_HOME/sbin/start-all.sh
```

**Importante:** Não execute este comando nos nós slaves\!

-----

## 📊 Monitoramento e Interfaces Web

Acesse as seguintes interfaces web para gerenciar e monitorar seu cluster.

| Serviço | Porta | URL |
| :--- | :---: | :--- |
| **HDFS NameNode** | `9870` | `http://master:9870` |
| **HDFS DataNode** | `9864` | `http://slave1:9864` |
| **YARN ResourceManager** | `8088` | `http://master:8088` |
| **Zabbix** | `80` | `http://localhost/zabbix` |
| **Grafana** | `3000` | `http://localhost:3000` |
| **Portainer** | `9000` | `http://localhost:9000` |

-----

## 🧪 Verificação e Testes

### ✅ Etapa 9 — Verificar Processos em Execução

Use o comando `jps` para verificar se os serviços do Hadoop estão rodando corretamente.

  - **No Master, a saída esperada é:**

    ```
    NameNode
    ResourceManager
    SecondaryNameNode
    ```

  - **Em cada Slave, a saída esperada é:**

    ```
    DataNode
    NodeManager
    ```

### ⚡ Etapa 10 — Gerar Dados de Teste com TeraGen

Use o `TeraGen`, uma ferramenta do Hadoop, para gerar uma grande quantidade de dados e testar a capacidade de processamento do cluster.

1.  Navegue até o diretório de exemplos MapReduce:

    ```bash
    cd $HADOOP_HOME/share/hadoop/mapreduce/
    ```

2.  Execute o `TeraGen` para gerar dados. O exemplo abaixo cria dados no diretório `/hadoop/teragen` dentro do HDFS.

    ```bash
    hadoop jar hadoop-mapreduce-examples-3.4.0.jar teragen 508080808 /hadoop/teragen
    ```

3.  Você pode acompanhar o progresso do job MapReduce através da interface web do **ResourceManager**:
    🔗 `http://master:8088`

-----

## 🤝 Contribuições

Sugestões e melhorias são sempre bem-vindas\! Sinta-se à vontade para abrir uma **issue** para relatar problemas ou enviar um **pull request** com novas funcionalidades.

## 📄 Licença

Este projeto é distribuído sob a licença MIT. Consulte o arquivo `LICENSE` para mais detalhes.