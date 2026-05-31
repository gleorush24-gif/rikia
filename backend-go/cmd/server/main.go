package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/rikia/api/internal/db"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Connect to database
	db.Connect()

	// Run migrations (create tables if they don't exist)
	db.Migrate()

	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"service": "rikia-api",
			"status":  "ok",
		})
	})

	fmt.Printf("👁️  Rikia API running on port %s\n", port)
	log.Fatal(r.Run(":" + port))
}
