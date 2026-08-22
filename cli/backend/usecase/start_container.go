package usecase

import (
	"fmt"
	"os/exec"
	"strings"
	"sync"
	"time"

	"github.com/ericsanto/S.H.A.N.K.S/cli/backend/models"
)

func startSpinner(message string, done <-chan bool, fail chan bool) {

	frames := []string{"|", "/", "-", "\\"}
	i := 0

	for {
		select {
		case <-done:

			fmt.Printf("\r%s [ \033[32mOK\033[0m ]      \n", message)
			return

		case <-fail:
			fmt.Printf("\r%s [ \033[31mFAIL\033[0m ]          \n", message)

		default:

			fmt.Printf("\r%s %s", message, frames[i])

			i = (i + 1) % len(frames)
			time.Sleep(100 * time.Millisecond)
		}
	}
}

func StartCluster(configCluster models.Config) error {
	fmt.Println()
	fmt.Println()

	fmt.Println("\033[1;31m  ____   _   _      _      _   _   _  __  ____  \033[1;33m         ____      \033[0m")
	fmt.Println("\033[1;31m / ___| | | | |    / \\    | \\ | | | |/ / / ___| \033[1;33m       /      \\    \033[0m")
	fmt.Println("\033[1;31m \\___ \\ | |_| |   / _ \\   |  \\| | | ' /  \\___ \\ \033[1;31m      |========|   \033[0m")
	fmt.Println("\033[1;31m  ___) ||  _  |_ / ___ \\ _| |\\  |_| . \\ _ ___) |\033[1;33m    _/__|____|__\\_ \033[0m")
	fmt.Println("\033[1;31m |____(_)_| |_(_)_/   \\_(_)_| \\_(_)_|\\_(_)____/ \033[1;33m   (______________)\033[0m")

	fmt.Println()
	fmt.Println()

	done := make(chan bool)
	fail := make(chan bool)
	isImageBuildOK := make(chan bool, 1)
	errors := make(chan error)
	resultImageBuildVerifiedDatanode := make(chan string, len(configCluster.Cluster.Datanodes))
	// resultImageBuildVerifiedMaster := make(chan bool, 1)

	var wg sync.WaitGroup

	go startSpinner("Iniciando cluster...", done, fail)
	time.Sleep(time.Second * 3)
	done <- true

	home, err := getHomeDir()

	if err != nil {
		return err
	}

	commandMaster := fmt.Sprintf("cd %s/S.H.A.N.K.S/new_cluster/master && docker compose -f 'docker-compose.master.yml' up -d --build", home)
	commandWorkers := "cd $HOME/S.H.A.N.K.S/new_cluster/worker && docker compose -f 'docker-compose.worker.yml' up -d --build"
	commandDockerBuildImage := fmt.Sprintf("cd %s/S.H.A.N.K.S/new_cluster && docker build --no-cache -t hadoop-base -f Dockerfile.base .", home)

	privatePathSSHKey, err := getPathPrivateKey()
	if err != nil {
		return err
	}

	go startSpinner("Verificando se a imagem docker já está buildada na master", done, fail)

	isImageBuilded := "docker images -q hadoop-base"
	out, err := exec.Command("bash", "-c", isImageBuilded).Output()

	if err != nil {
		fail <- true
		return fmt.Errorf("erro ao verificar se a imagem docker existe no host: %v", err)
	}
	done <- true

	resultFormated := strings.TrimSpace(string(out))

	if resultFormated == "" {

		//FAZ O BUILD DA IMAGEM CASO NAO TENHA
		wg.Add(1)
		go buildImage(commandDockerBuildImage, done, fail, errors, &wg, isImageBuildOK)

	} else {
		isImageBuildOK <- true
	}

	//ESPERA O SINAL DO BUILD DA IMAGEM
	wg.Add(1)
	go startContainer(commandMaster, done, fail, isImageBuildOK, errors, &wg)

	for _, datanode := range configCluster.Cluster.Datanodes {

		wg.Add(1)
		go verifyImageBuildInDatanode(datanode, done, fail, errors, resultImageBuildVerifiedDatanode, privatePathSSHKey, isImageBuilded, &wg)

		wg.Add(1)
		go imageBuildDatanode(datanode, resultImageBuildVerifiedDatanode, done, fail, privatePathSSHKey, commandDockerBuildImage, errors, &wg)

		wg.Add(1)
		go startContainerDatanode(datanode, done, fail, privatePathSSHKey, commandWorkers, errors, &wg)

	}

	wg.Wait()

	close(errors)

	for err := range errors {
		if err != nil {
			return err
		}

	}

	fmt.Println("\n ☠️🗡️ Cluster Iniciado com Sucesso!")
	return nil
}

func buildImage(commandImageBuilder string, done chan bool, fail chan bool, errors chan<- error, wg *sync.WaitGroup, isImageBuildOK chan<- bool) {

	defer wg.Done()
	go startSpinner("Imagem não encontrada na master. Fazendo build (aguarde)...", done, fail)

	outBuild, errBuild := exec.Command("bash", "-c", commandImageBuilder).CombinedOutput()

	if errBuild != nil {
		fail <- true
		errors <- fmt.Errorf("erro ao fazer o build da imagem na master: %v\nLogs: %s", errBuild, string(outBuild))

	}

	done <- true
	isImageBuildOK <- true

}

func startContainer(commandMaster string, done, fail chan bool, isBuildImageOK <-chan bool, errors chan<- error, wg *sync.WaitGroup) {

	defer wg.Done()

	if <-isBuildImageOK {
		go startSpinner("Iniciando container na master", done, fail)
		_, err := exec.Command("bash", "-c", commandMaster).CombinedOutput()
		if err != nil {
			fail <- true
			errors <- err

		}
		done <- true
	} else {
		fail <- false
	}

	go startSpinner("Container Iniciado", done, fail)
	done <- true

}

func verifyImageBuildInDatanode(datanode models.Datanode, done, fail chan bool, errors chan<- error, resultImageBuildVerifiedDatanode chan<- string, privatePathSSHKey, isImageBuilded string,
	wg *sync.WaitGroup) {

	defer wg.Done()
	go startSpinner(fmt.Sprintf("Verificando se a imagem está buildada no datanode %s", datanode.Name), done, fail)

	outSsh, err := runSSHCommand(datanode.IP, "22", datanode.User, privatePathSSHKey, isImageBuilded)
	if err != nil {
		fail <- true
		errors <- fmt.Errorf("erro na verificação do build no datanode %s: %v", datanode.Name, err)
	}
	done <- true

	resultImageBuildVerifiedDatanode <- strings.TrimSpace(outSsh)

}

func imageBuildDatanode(datanode models.Datanode, resultImageBuildVerifiedDatanode <-chan string, done, fail chan bool, privatePathSSHKey, commandDockerBuildImage string, errors chan<- error,
	wg *sync.WaitGroup) {

	defer wg.Done()
	output := <-resultImageBuildVerifiedDatanode

	if output == "" {
		go startSpinner(fmt.Sprintf("Imagem não encontrada no datanode %s. Fazendo build (aguarde)...", datanode.Name), done, fail)

		outBuild, err := runSSHCommand(datanode.IP, "22", datanode.User, privatePathSSHKey, commandDockerBuildImage)

		if err != nil {
			fail <- true
			errors <- fmt.Errorf("erro ao fazer o build da imagem no datanode: %v\nLogs: %s", err, outBuild)
		}

		done <- true

	}
}

func startContainerDatanode(datanode models.Datanode, done, fail chan bool, privatePathSSHKey, commandWorkers string, errors chan<- error, wg *sync.WaitGroup) {

	defer wg.Done()

	go startSpinner(fmt.Sprintf("Subindo container do datanode %s", datanode.Name), done, fail)

	_, err := runSSHCommand(datanode.IP, "22", datanode.User, privatePathSSHKey, commandWorkers)
	if err != nil {
		fail <- true
		errors <- fmt.Errorf("erro ao subir container no datanode %s: %v", datanode.Name, err)
	}
	done <- true
}
