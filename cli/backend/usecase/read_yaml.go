package usecase

import (
	"fmt"
	"os"

	"github.com/ericsanto/S.H.A.N.K.S/cli/backend/models"
	"gopkg.in/yaml.v3"
)

func ReadYaml(pathFile string) (*models.Config, error) {
	file, err := os.ReadFile(pathFile)
	if err != nil {
		return nil, fmt.Errorf("erro ao abrir arquivo config.yaml %v", err)
	}

	var cluster models.Config

	if err := yaml.Unmarshal(file, &cluster); err != nil {
		return nil, fmt.Errorf("erro ao fazer unmarshal do arquivo config.yaml %v", err)
	}

	return &cluster, nil
}
