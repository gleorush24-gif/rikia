package handlers

import (
	"encoding/base64"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// UploadImage — accepts base64 image and saves it
func UploadImage(c *gin.Context) {
	var req struct {
		Image string `json:"image" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Image data required"})
		return
	}

	// Strip data:image/jpeg;base64, prefix
	parts := strings.Split(req.Image, ",")
	if len(parts) != 2 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid image format"})
		return
	}

	// Decode base64
	imageData, err := base64.StdEncoding.DecodeString(parts[1])
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to decode image"})
		return
	}

	// Create uploads directory
	os.MkdirAll("/app/uploads", 0755)

	// Save file
	filename := fmt.Sprintf("%s_%d.jpg", uuid.New().String(), time.Now().Unix())
	filepath := filepath.Join("/app/uploads", filename)

	if err := os.WriteFile(filepath, imageData, 0644); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save image"})
		return
	}

	// Return URL
	host := "https://rikia-api.onrender.com"
	url := fmt.Sprintf("%s/uploads/%s", host, filename)

	c.JSON(http.StatusOK, gin.H{"url": url})
}
