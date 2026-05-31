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

	db.Connect()
	db.Migrate()
	db.MigrateNotifications()

	r := gin.Default()
	r.Use(middleware.CORS())

	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"service": "rikia-api", "status": "ok"})
	})

	// Initialize handlers
	auth := handlers.NewAuthHandler(db.DB)
	posts := handlers.NewPostHandler(db.DB)
	interactions := handlers.NewInteractionHandler(db.DB)
	follows := handlers.NewFollowHandler(db.DB)
	stories := handlers.NewStoryHandler(db.DB)
	search := handlers.NewSearchHandler(db.DB)
	notifications := handlers.NewNotificationHandler(db.DB)

	// Public routes
	api := r.Group("/api/v1")
	{
		api.POST("/auth/register", auth.Register)
		api.POST("/auth/login", auth.Login)
		api.GET("/users/:id", follows.GetProfile)
		api.GET("/users/:id/followers", follows.GetFollowers)
		api.GET("/users/:id/following", follows.GetFollowing)
		api.GET("/search/users", search.SearchUsers)
		api.GET("/search/posts", search.SearchPosts)
	}

	// Protected routes
	protected := api.Group("/")
	protected.Use(middleware.AuthRequired())
	{
		// User
		protected.GET("/me", func(c *gin.Context) {
			userID := c.GetString("user_id")
			c.JSON(200, gin.H{"user_id": userID, "message": "You are authenticated!"})
		})

		// Posts
		protected.POST("/posts", posts.CreatePost)
		protected.GET("/feed", posts.GetFeed)
		protected.GET("/posts/:id", posts.GetPost)
		protected.DELETE("/posts/:id", posts.DeletePost)

		// Likes
		protected.POST("/posts/:id/like", interactions.LikePost)

		// Comments
		protected.POST("/posts/:id/comments", interactions.AddComment)
		protected.GET("/posts/:id/comments", interactions.GetComments)
		protected.DELETE("/comments/:id", interactions.DeleteComment)

		// Follows
		protected.POST("/users/:id/follow", follows.Follow)

		// Stories
		protected.POST("/stories", stories.CreateStory)
		protected.GET("/stories", stories.GetStories)
		protected.DELETE("/stories/:id", stories.DeleteStory)

		// Notifications
		protected.GET("/notifications", notifications.GetNotifications)
		protected.PUT("/notifications/read", notifications.MarkAsRead)
	}

	fmt.Printf("👁️  Rikia API running on port %s\n", port)
	log.Fatal(r.Run(":" + port))
}
