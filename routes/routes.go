package routes

import (
	"api/server"

	"github.com/labstack/echo/v4"
)

func ConfigurationsRoutes(e *echo.Echo) {

	e.GET("/api/list-all-containers", server.APIListAllContainerHandler)
	e.GET("/api/list-exec-containers", server.APIListExecContainerHandler)
	e.POST("/api/:id/stop-container", server.APIStopContainerHandle)
	e.POST("/api/:id/start-container", server.APIStartContainerHandle)
	e.GET("/api/containers/:id/statics", server.APIStatsContainerHandle)
	e.GET("/api/containers/:id/inspect", server.APIInspectContainer)
	e.POST("/api/containers/:id/update", server.APIUpdateContainerHandle)
}
