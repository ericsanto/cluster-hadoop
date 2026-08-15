package usecase

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/ericsanto/S.H.A.N.K.S/cli/backend/models"
)

func ConfigureYarnLimits(configCluster models.Config) error {

	yarnMaster, err := configCluster.Cluster.Namenode.ConvertToYarnLimit()

	if err != nil {
		return fmt.Errorf("erro ao converter o limite de memória do Yarn do Namenode: %v", err)
	}

	pathPrivateKey, err := getPathPrivateKey()
	if err != nil {
		return err
	}

	validatedYarnMaster, err := validateYarnLimits(configCluster.Cluster.Namenode.IP, configCluster.Cluster.Namenode.User, pathPrivateKey, yarnMaster)
	if err != nil {
		return err
	}

	configCluster.Cluster.Namenode.YarnLimit = *validatedYarnMaster

	yarnWorkers := make([]models.Datanode, len(configCluster.Cluster.Datanodes)-1)

	for _, datanode := range configCluster.Cluster.Datanodes {

		yarnLimit, err := datanode.ConvertToYarnLimit()
		if err != nil {
			return fmt.Errorf("erro ao converter o limite de memória do Yarn do Datanode %s: %v", datanode.Name, err)
		}

		validatedYarnLimit, err := validateYarnLimits(datanode.IP, datanode.User, pathPrivateKey, yarnLimit)
		if err != nil {
			return err
		}

		datanode.YarnLimit = *validatedYarnLimit
		yarnWorkers = append(yarnWorkers, datanode)
	}

	if err := insertYarnLimitsToEnvFile(configCluster.Cluster.Namenode, yarnWorkers, pathPrivateKey); err != nil {
		return err
	}

	return nil

}

func validateYarnLimits(ip, user, pathPrivateKey string, yarnLimit float64) (*string, error) {

	memory, err := runSSHCommand(ip, "22", user, pathPrivateKey, "free -m | awk 'NR==2{print $2}'")
	if err != nil {
		return nil, err
	}

	intMemory, err := strconv.ParseFloat(strings.TrimSpace(memory), 64)
	if err != nil {
		return nil, err
	}

	if intMemory < yarnLimit {
		yarnLimit = intMemory * 70 / 100
		yarnLimitStr := strconv.FormatFloat(yarnLimit, 'f', -1, 64)
		return &yarnLimitStr, nil

	} else {
		yarnLimitStr := strconv.FormatFloat(yarnLimit, 'f', -1, 64)
		return &yarnLimitStr, nil
	}
}

func insertYarnLimitsToEnvFile(namenode models.Namenode, datanodes []models.Datanode, pathPrivateKey string) error {

	var stringBuffer strings.Builder

	file, err := os.OpenFile(".env", os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("erro ao abrir o arquivo .env: %v", err)
	}
	defer file.Close()

	stringBuffer.WriteString(fmt.Sprintf("namenode_YARN_LIMIT=%s\n", namenode.YarnLimit))

	for i, datanode := range datanodes {
		stringBuffer.WriteString(fmt.Sprintf("datanode_%d_YARN_LIMIT=%s\n", i+1, datanode.YarnLimit))

	}

	command := fmt.Sprintf(`touch ~/S.H.A.N.K.S/.env && sed -i '/###ENVS S.H.A.N.K.S###/,/###ENVS S.H.A.N.K.S###/d' ~/S.H.A.N.K.S/.env && echo -e '###ENVS S.H.A.N.K.S###\n%s###ENVS S.H.A.N.K.S###'  >> ~/S.H.A.N.K.S/.env`, stringBuffer.String())

	for _, datanode := range datanodes {
		if _, err := runSSHCommand(datanode.IP, "22", datanode.User, pathPrivateKey, command); err != nil {
			return err
		}
	}

	_, err = file.WriteString(stringBuffer.String())
	if err != nil {
		return fmt.Errorf("erro ao escrever no arquivo .env: %v", err)
	}

	return nil
}
