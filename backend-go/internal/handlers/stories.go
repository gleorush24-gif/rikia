package handlers

import (
	"database/sql"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type StoryHandler struct {
	db *sql.DB
}

func NewStoryHandler(db *sql.DB) *StoryHandler {
	return &StoryHandler{db: db}
}

// CreateStory — creates a new story (expires in 24 hours)
func (h *StoryHandler) CreateStory(c *gin.Context) {
	userID := c.GetString("user_id")

	var req struct {
		MediaURL string `json:"media_url" binding:"required"`
		Caption  string `json:"caption"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Media URL is required"})
		return
	}

	id := uuid.New().String()

	_, err := h.db.Exec(`
		INSERT INTO stories (id, user_id, media_url, caption)
		VALUES ($1, $2::uuid, $3, $4)`,
		id, userID, req.MediaURL, req.Caption)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create story"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":      id,
		"message": "Story created! It will disappear in 24 hours.",
	})
}

// GetStories — get active stories from people you follow
func (h *StoryHandler) GetStories(c *gin.Context) {
	userID := c.GetString("user_id")

	// Get stories that:
	// 1. Are not expired (expires_at > NOW())
	// 2. Are from people you follow OR yourself
	// 3. Grouped by user so you see one bubble per user
	rows, err := h.db.Query(`
		SELECT s.id, s.media_url, s.caption, s.created_at, s.expires_at,
		       u.id as user_id, u.username, u.avatar_url
		FROM stories s
		JOIN users u ON u.id = s.user_id
		WHERE s.expires_at > NOW()
		  AND (
		    s.user_id::text = $1
		    OR s.user_id IN (
		      SELECT following_id FROM follows WHERE follower_id::text = $1
		    )
		  )
		ORDER BY s.created_at DESC`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get stories"})
		return
	}
	defer rows.Close()

	type Story struct {
		ID        string    `json:"id"`
		MediaURL  string    `json:"media_url"`
		Caption   string    `json:"caption"`
		CreatedAt time.Time `json:"created_at"`
		ExpiresAt time.Time `json:"expires_at"`
		UserID    string    `json:"user_id"`
		Username  string    `json:"username"`
		AvatarURL string    `json:"avatar_url"`
	}

	stories := []Story{}
	for rows.Next() {
		var s Story
		rows.Scan(&s.ID, &s.MediaURL, &s.Caption, &s.CreatedAt, &s.ExpiresAt,
			&s.UserID, &s.Username, &s.AvatarURL)
		stories = append(stories, s)
	}

	c.JSON(http.StatusOK, gin.H{"stories": stories})
}

// DeleteStory — delete your own story
func (h *StoryHandler) DeleteStory(c *gin.Context) {
	userID := c.GetString("user_id")
	storyID := c.Param("id")

	var ownerID string
	err := h.db.QueryRow(`SELECT user_id FROM stories WHERE id::text=$1`, storyID).Scan(&ownerID)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Story not found"})
		return
	}

	if ownerID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only delete your own stories"})
		return
	}

	h.db.Exec(`DELETE FROM stories WHERE id::text=$1`, storyID)
	c.JSON(http.StatusOK, gin.H{"message": "Story deleted"})
}
