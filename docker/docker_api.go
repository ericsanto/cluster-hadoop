package docker

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/docker/docker/api/types"
	"github.com/docker/docker/api/types/container"
	containertypes "github.com/docker/docker/api/types/container"
	"github.com/docker/docker/client"
)

// Lista containers
func GetAllContainer() ([]types.Container, error) {
	cli, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		log.Printf("Erro ao conectar o cliente Docker: %s", err)
		return nil, err
	}

	defer cli.Close()

	containers, err := cli.ContainerList(context.Background(), containertypes.ListOptions{All: true})
	if err != nil {
		log.Printf("Erro ao listar containers: %s", err)
		return nil, err
	}

	return containers, nil
}

func GetExecContainer() ([]types.Container, error) {
	cli, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		log.Printf("Erro ao conectar o cliente Docker: %s", err)
		return nil, err
	}

	defer cli.Close()

	containers, err := cli.ContainerList(context.Background(), containertypes.ListOptions{})
	if err != nil {
		log.Printf("Erro ao listar containers: %s", err)
		return nil, err
	}

	return containers, nil
}

// Parar containers
func StopContainer(containerID string) ([]types.Container, error) {
	cli, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		log.Printf("Erro ao conectar cliente ao Docker: %s", err)
		return nil, err
	}

	defer cli.Close()

	ctx := context.Background()

	fmt.Printf("Parando container %s...\n", containerID[:10])
	timeout := 10 // 10 segundos de timeout para parar o container
	if err := cli.ContainerStop(ctx, containerID, containertypes.StopOptions{Timeout: &timeout}); err != nil {
		log.Printf("Erro ao parar container %s: %s", containerID[:10], err)
		return nil, err
	}
	fmt.Printf("Container %s parado com sucesso.\n", containerID[:10])

	return nil, err
}

func StartContainer(containerID string) ([]types.Container, error) {
	cli, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		log.Printf("Erro ao conectar cliente ao Docker: %s", err)
		return nil, err
	}

	defer cli.Close()

	ctx := context.Background()

	if err := cli.ContainerStart(ctx, containerID[:10], containertypes.StartOptions{}); err != nil {
		log.Println("Erro ao iniciar container %s:%s", containerID[:10], err)
		return nil, err
	}

	return nil, err
}

func StatsContainer(containerID string) (*container.StatsResponse, error) {
	cli, err := client.NewClientWithOpts(client.FromEnv)
	if err != nil {
		log.Printf("Erro ao conectar cliente ao Docker: %s", err)
		return nil, err
	}

	defer cli.Close()

	ctx := context.Background()

	stats, err := cli.ContainerStats(ctx, containerID[:10], false)

	if err != nil {
		fmt.Errorf("Erro ao obter métricas %s", err)
	}

	defer stats.Body.Close()

	var statsData container.StatsResponse

	err = json.NewDecoder(stats.Body).Decode(&statsData)

	if err != nil {
		log.Printf("Erro ao decodificar métricas: %s", err)
		return nil, err
	}

	return &statsData, nil
}
