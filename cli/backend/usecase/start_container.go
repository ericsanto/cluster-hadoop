package usecase

import (
	"fmt"
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

	fmt.Println(`  ____   _   _      _      _   _   _  __  ____  
 / ___| | | | |    / \    | \ | | | |/ / / ___| 
 \___ \ | |_| |   / _ \   |  \| | | ' /  \___ \ 
  ___) ||  _  |_ / ___ \ _| |\  |_| . \ _ ___) |
 |____(_)_| |_(_)_/   \_(_)_| \_(_)_|\_(_)____/ 
                                                `)

	fmt.Println()
	fmt.Println()

	done := make(chan bool)
	fail := make(chan bool)

	go startSpinner("Iniciando cluster...", done, fail)

	time.Sleep(time.Second * 10)

	done <- true

	commandMaster := "cd $HOME/S.H.A.N.K.S/new_cluster/master && docker compose -f 'docker-compose.master.yml' up -d --force-recreate"
	commandWorkers := "cd $HOME/S.H.A.N.K.S/new_cluster/worker && docker compose -f 'docker-compose.worker.yml' up -d --force-recreate"

	privatePathSSHKey, err := getPathPrivateKey()
	if err != nil {
		return err
	}

	go startSpinner("Subindo container da master", done, fail)

	_, err = runSSHCommand(configCluster.Cluster.Namenode.IP, "22", configCluster.Cluster.Namenode.User, privatePathSSHKey, commandMaster)

	if err != nil {

		fail <- true
		return err
	}

	for _, datanode := range configCluster.Cluster.Datanodes {

		datanodeF := fmt.Sprintf("Subindo container do datanode %s ", datanode.Name)
		go startSpinner(datanodeF, done, fail)

		_, err = runSSHCommand(datanode.IP, "22", datanode.User, privatePathSSHKey, commandWorkers)

		if err != nil {
			fail <- true
			return err
		}

		done <- true
	}

	fmt.Println("Cluster Iniciado")

	return nil

}
