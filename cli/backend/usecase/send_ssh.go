package usecase

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/ericsanto/S.H.A.N.K.S/cli/backend/models"
	"golang.org/x/crypto/ssh"
	"golang.org/x/term"
)

func ConfigHosts(c models.Config) error {
	senhaUser := LerSenhaInterativa()

	if senhaUser == "" {
		return fmt.Errorf("senha nao pode ser vazia")
	}
	nameNode := fmt.Sprintf("%s %s\n", c.Cluster.Namenode.IP, c.Cluster.Namenode.Name)
	path := "/etc/hosts"

	file, err := os.OpenFile(path, os.O_APPEND|os.O_WRONLY, 644)
	if err != nil {
		if os.IsPermission(err) {
			return fmt.Errorf("erro %v", err)
		}

		return fmt.Errorf("erro %v", err)
	}

	defer file.Close()

	var bufferDatanodes strings.Builder

	bufferDatanodes.WriteString(nameNode)
	bufferDatanodes.WriteString("\n")

	for _, datanode := range c.Cluster.Datanodes {

		dataNodeString := fmt.Sprintf("%s %s", datanode.IP, datanode.Name)

		bufferDatanodes.WriteString(dataNodeString)
		bufferDatanodes.WriteString("\n")

	}

	privateKey, err := ObterCaminhoChavePrivada()
	if err != nil {
		return err
	}

	command := fmt.Sprintf(`echo "%s" | sudo -S sh -c 'echo "%s" >> /etc/hosts'`, senhaUser, bufferDatanodes.String())

	for _, datanode := range c.Cluster.Datanodes {
		// Preciso me conectar via ssh no datanode e escrever no arquivoe/etc/hosts
		_, err := RunSSHCommand(datanode.IP, "22", datanode.User, privateKey, command)
		if err != nil {
			return err
		}
	}

	//if _, err = file.WriteString(bufferDatanodes.String()); err != nil {
	//return fmt.Errorf("erro %v", err)
	//}

	return nil
}

func RunSSHCommand(ip string, port string, username string, privateKeyPath string, command string) (string, error) {
	
	key, err := os.ReadFile(privateKeyPath)
	if err != nil {
		return "", fmt.Errorf("não foi possível ler a chave privada: %v", err)
	}

		signer, err := ssh.ParsePrivateKey(key)
	if err != nil {
		return "", fmt.Errorf("formato de chave privada inválido: %v", err)
	}

	
	config := &ssh.ClientConfig{
		User: username,
		Auth: []ssh.AuthMethod{
			ssh.PublicKeys(signer),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         10 * time.Second, // Desiste se o Worker estiver desligado
	}

	
	endereco := fmt.Sprintf("%s:%s", ip, port)
	client, err := ssh.Dial("tcp", endereco, config)
	if err != nil {
		return "", fmt.Errorf("falha ao conectar no IP %s: %v", ip, err)
	}
	defer client.Close()

	
	session, err := client.NewSession()
	if err != nil {
		return "", fmt.Errorf("falha ao abrir sessão ssh: %v", err)
	}
	defer session.Close()

	
	output, err := session.CombinedOutput(command)
	if err != nil {
		return string(output), fmt.Errorf("erro ao rodar comando '%s': %v\nSaída: %s", command, err, string(output))
	}

	return string(output), nil
}

func ObterCaminhoChavePrivada() (string, error) {
	var home string

	
	sudoUser := os.Getenv("SUDO_USER")

	if sudoUser != "" {
	.
		u, err := user.Lookup(sudoUser)
		if err != nil {
			return "", fmt.Errorf("erro ao buscar o usuário original do sudo: %v", err)
		}
		home = u.HomeDir
	} else {
	
		h, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("erro ao localizar o diretório HOME: %v", err)
		}
		home = h
	}


	caminhoCompleto := filepath.Join(home, ".ssh", "id_rsa")

	return caminhoCompleto, nil
}


func LerSenhaInterativa() string {
	fmt.Print("🔑 Digite a senha sudo dos Workers (ela não vai aparecer na tela): ")


	bytePassword, err := term.ReadPassword(int(syscall.Stdin))
	fmt.Println() 

	if err != nil {
		fmt.Printf("Erro ao ler a senha: %v\n", err)
		return ""
	}

	return string(bytePassword)
}
