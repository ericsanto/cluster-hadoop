package main

import (
	"api/routes"
	"log"

	"github.com/labstack/echo/v4"
)

func main() {
	e := echo.New()

	routes.ConfigurationsRoutes(e)

	// Inicia o servidor
	log.Println("Servidor rodando na porta 8080...")
	e.Logger.Fatal(e.Start("localhost:8080"))
}
