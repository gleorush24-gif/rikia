package middleware

import (
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// AuthRequired is a middleware that checks for a valid JWT token
// Think of it as a bouncer at a club — checks your wristband before letting you in
func AuthRequired() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get the Authorization header
		// It looks like: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Missing token"})
			c.Abort() // Stop processing this request
			return
		}

		// Split "Bearer <token>" and get just the token part
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token format"})
			c.Abort()
			return
		}

		tokenString := parts[1]

		// Verify the token
		secret := os.Getenv("JWT_SECRET")
		if secret == "" {
			secret = "rikia-default-secret"
		}

		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			return []byte(secret), nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			c.Abort()
			return
		}

		// Extract user ID from token and store it in context
		// So handlers can access it with c.GetString("user_id")
		claims := token.Claims.(jwt.MapClaims)
		c.Set("user_id", claims["sub"].(string))

		// Continue to the next handler
		c.Next()
	}
}
