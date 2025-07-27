
```markdown
# 🚀 Cluster Hadoop com Monitoramento via Docker

Projeto para configuração de um ambiente **Hadoop distribuído**, com suporte a **Docker**, **Zabbix**, **Grafana**, **Portainer** e **ZeroTier** para simular clusters locais e remotos.

---

## 📦 Requisitos

- Linux (Ubuntu/Debian)
- Docker e Docker Compose
- ZeroTier (opcional, para conectar máquinas remotas)

---

## 🧩 Etapa 1 — Instalar e configurar ZeroTier (opcional)

Usado para simular uma rede virtual entre máquinas remotas.

### Instalar

```bash
curl -s https://install.zerotier.com | sudo bash
```

### Criar rede

1. Acesse [https://my.zerotier.com](https://my.zerotier.com)
2. Crie uma rede e copie o **Network ID**
3. Em cada máquina:
   ```bash
   sudo zerotier-cli join <ID_DA_REDE>
   ```
4. Autorize os dispositivos via painel web

---

## 🧭 Etapa 2 — Editar arquivo /etc/hosts

Em todas as máquinas que fazem parte do cluster, adicione os IPs da rede:

```bash
sudo nano /etc/hosts
```

Exemplo:
```
10.147.17.1    master
10.147.17.2    slave1
```

---

## 🧰 Etapa 3 — Clonar o projeto e construir imagem

```bash
git clone https://github.com/ericsanto/cluster-hadoop.git
cd cluster-hadoop
sudo docker build -t hadoop .
```

---

## 🐳 Etapa 4 — Executar container

Em cada máquina (master e slaves):

```bash
sudo docker run -it --network host hadoop
```

---

## 🔄 Etapa 5 — Alternar para o usuário Hadoop

```bash
su hadoop
```

---

## ⚙️ Etapa 6 — Automatizar configuração do nó

### No nó master:

```bash
./automatization-cluster.sh --config master --slaves 1 --memory-ram 5000
```

### No nó slave:

```bash
./automatization-cluster.sh --config slave --slaves 1 --memory-ram 5000
```

---

## 🧱 Etapa 7 — Formatar o NameNode (somente na master)

Antes de iniciar os serviços:

```bash
hdfs namenode -format
```

---

## ▶️ Etapa 8 — Iniciar serviços Hadoop (somente na master)

```bash
$HADOOP_HOME/sbin/start-all.sh
```

Evite rodar este comando nos slaves!

---

## 📊 Etapa 9 — Monitoramento e interfaces web

| Serviço         | Porta | URL                   |
|----------------|-------|------------------------|
| NameNode        | 9870  | http://master:9870     |
| DataNode        | 9864  | http://slave1:9864     |
| ResourceManager | 8088  | http://master:8088     |
| Zabbix          | 80    | http://localhost/zabbix|
| Grafana         | 3000  | http://localhost:3000  |
| Portainer       | 9000  | http://localhost:9000  |

---

## 🧪 Etapa 10 — Gerar dados de teste com Teragen

```bash
cd hadoop/share/hadoop/mapreduce/
hadoop jar hadoop-mapreduce-examples-3.4.0.jar teragen 508080808 /hadoop/teragen
```

Acompanhe o progresso pelo ResourceManager:  
🔗 `http://master:8088`

---

## 🧼 Etapa 11 — Verificação com jps

### Na master:

```bash
jps
```

Saída esperada:
```
NameNode
ResourceManager
SecondaryNameNode
```

### No slave:

```bash
jps
```

Saída esperada:
```
DataNode
NodeManager
```

---

## 🤝 Contribuições

Sugestões e melhorias são bem-vindas!  
Abra uma issue ou envie um pull request.

---

## 📄 Licença

Distribuído sob a licença [MIT](LICENSE).

---

Feito com 💻 e ☕ por [**Éric Santos**](https://github.com/ericsanto)
```

Se quiser, posso exportar esse passo a passo como infográfico, transformar num artigo técnico, ou te ajudar a publicar no DockerHub. O que acha de dar uma cara de curso gratuito pro projeto? 😎📚