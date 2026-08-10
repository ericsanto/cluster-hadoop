package models

import "strconv"

type Datanode struct {
	User       string `yaml:"user"`
	Name       string `yaml:"name"`
	IP         string `yaml:"ip"`
	YarnLimit  string `yaml:"yarn_limit"`
	SparkLimit string `yaml:"spark_limit"`
}

func (d *Datanode) ConvertToYarnLimit() (float64, error) {

	intYarnLimit, err := strconv.ParseFloat(d.YarnLimit, 64)
	if err != nil {
		return 0, err
	}

	byteYarnLimit := intYarnLimit * 1000

	return byteYarnLimit, nil

}
