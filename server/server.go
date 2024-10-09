package server

import (
	"api/docker"
	"net/http"

	"github.com/labstack/echo/v4"
)

type StopAndStartContainerRequest struct {
	ContainerID string `json:"container_id"`
}

type StatsContainer struct {
	StopAndStartContainerRequest
	CPUUsage     float64 `json:"cpu_usage"`
	RAMUsage     float64 `json:"ram_usage"`
	NetworkUsage float64 `json:"network_usage"`
}

func APIListAllContainerHandler(c echo.Context) error {
	container, err := docker.GetAllContainer()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Erro listar container"})
	}

	return c.JSON(200, container)
}

func APIListExecContainerHandler(c echo.Context) error {
	container, err := docker.GetExecContainer()
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Erro ao listar container"})
	}

	return c.JSON(http.StatusOK, container)
}

func APIStopContainerHandle(c echo.Context) error {
	containerID := c.Param("id")

	container, err := docker.StopContainer(containerID)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Erro ao parar container"})
	}

	return c.JSON(http.StatusOK, container)
}

func APIStartContainerHandle(c echo.Context) error {
	containerID := c.Param("id")

	container, err := docker.StartContainer(containerID)

	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Erro ao obter containers"})
	}

	return c.JSON(http.StatusOK, container)
}

func APIStatsContainerHandle(c echo.Context) error {

	containerID := c.Param("id")

	statsData, err := docker.StatsContainer(containerID)

	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Erro ao obter métricas"})
	}

	return c.JSON(http.StatusOK, statsData)

}
