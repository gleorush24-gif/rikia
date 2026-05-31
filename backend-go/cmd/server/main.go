package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/rikia/api/internal/db"
	"github.com/rikia/api/internal/handlers"
	"github.com/rikia/api/internal/middleware"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Connect to database and run migrations
	db.Connect()
	db.Migrate()

	r := gin.Default()

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"service": "rikia-api", "status": "ok"})
	})

	// Initialize handlers
	auth := handlers.NewAuthHandler(db.DB)

	// Public routes — no token needed
	api := r.Group("/api/v1")
	{
		api.POST("/auth/register", auth.Register)
		api.POST("/auth/login", auth.Login)
	}

	// Protected routes — token required
	protected := api.Group("/")
	protected.Use(middleware.AuthRequired())
	{
		// We will add more routes here soon
		protected.GET("/me", func(c *gin.Context) {
			userID := c.GetString("user_id")
			c.JSON(200, gin.H{"user_id": userID, "message": "You are authenticated!"})
		})
	}

	fmt.Printf("👁️  Rikia API running on port %s\n", port)
	log.Fatal(r.Run(":" + port))
}
