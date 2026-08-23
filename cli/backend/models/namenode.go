package models

import (
	"fmt"
	"strconv"
)

type Namenode struct {
	User       string `yaml:"user"`
	Name       string `yaml:"name"`
	IP         string `yaml:"ip"`
	YarnLimit  string `yaml:"yarn_limit"`
	SparkLimit string `yaml:"spark_limit"`
}

func (n *Namenode) ConvertToYarnLimit() (float64, error) {

	intYarnLimit, err := strconv.ParseFloat(n.YarnLimit, 64)
	if err != nil {
		return 0, err
	}

	byteYarnLimit := intYarnLimit * 1000

	return byteYarnLimit, nil

}

func (n *Namenode) VerifiyValueMinYarnRequirements() error {

	yarnLimit, err := n.ConvertToYarnLimit()
	if err != nil {
		return err
	}

	if yarnLimit < 1024 {
		return fmt.Errorf("o limite de memória do Yarn para o Namenode %s é menor que o mínimo requerido (1024 MB)", n.Name)
	}

	return nil
}
