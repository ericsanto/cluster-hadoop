package usecase

import (
	"fmt"
	"os/exec"
	"time"

	"github.com/ericsanto/S.H.A.N.K.S/cli/backend/models"
)

func StopCluster(configCluster models.Config) error {

	done := make(chan bool)
	fail := make(chan bool)

	go startSpinner("Interrompendo cluster...", done, fail)
	time.Sleep(time.Second * 3)
	done <- true

	home, err := getHomeDir()

	if err != nil {
		return err
	}

	commandMaster := fmt.Sprintf("cd %s/S.H.A.N.K.S/new_cluster/master && docker compose -f 'docker-compose.master.yml' down", home)
	commandWorkers := "cd $HOME/S.H.A.N.K.S/new_cluster/worker && docker compose -f 'docker-compose.worker.yml' down"

	privatePathSSHKey, err := getPathPrivateKey()
	if err != nil {
		return err
	}

	go startSpinner("Parando container da master", done, fail)
	out, err := exec.Command("bash", "-c", commandMaster).CombinedOutput()
	if err != nil {
		fail <- true
		return fmt.Errorf("erro ao subir a master: %v\nLogs: %s", err, string(out))
	}
	done <- true

	for _, datanode := range configCluster.Cluster.Datanodes {

		go startSpinner(fmt.Sprintf("Parando container do datanode %s", datanode.Name), done, fail)

		_, err = runSSHCommand(datanode.IP, "22", datanode.User, privatePathSSHKey, commandWorkers)
		if err != nil {
			fail <- true
			return fmt.Errorf("erro ao subir container no datanode %s: %v", datanode.Name, err)
		}
		done <- true
	}

	fmt.Println("\n ☠️🗡️ Cluster Parado com Sucesso!")
	return nil
}
