package server

import (
	"api/controllers"
	"api/docker"
	"net/http"

	"github.com/labstack/echo/v4"
)

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

func APIInspectContainer(c echo.Context) error {

	containerID := c.Param("id")

	inspectData, err := docker.GetInspectContainer(containerID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]string{"error": "Erro ao inspecionar container"})
	}

	return c.JSON(http.StatusOK, inspectData)
}

func APIUpdateContainerHandle(c echo.Context) error {

	var config controllers.UpdateRequestConfigContainer

	if err := c.Bind(&config); err != nil {
		c.JSON(http.StatusInternalServerError, map[string]string{"error": "erro ao deserializar dados"})
	}

	containerID := c.Param("id")

	containerUpdate, err := docker.UpdateContainer(containerID, config)

	if err != nil {
		c.JSON(http.StatusInternalServerError, map[string]string{"message": "Erro ao atualizar container"})
	}

	return c.JSON(http.StatusOK, containerUpdate)

}
