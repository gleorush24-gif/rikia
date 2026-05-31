package handlers

import (
	"database/sql"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type PostHandler struct {
	db *sql.DB
}

func NewPostHandler(db *sql.DB) *PostHandler {
	return &PostHandler{db: db}
}

// CreatePost — creates a new post
func (h *PostHandler) CreatePost(c *gin.Context) {
	userID := c.GetString("user_id")

	var req struct {
		Caption  string `json:"caption"`
		ImageURL string `json:"image_url"`
		VideoURL string `json:"video_url"`
		Location string `json:"location"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Every post needs at least a caption or an image
	if req.Caption == "" && req.ImageURL == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Post must have a caption or image"})
		return
	}

	id := uuid.New().String()

	_, err := h.db.Exec(`
		INSERT INTO posts (id, user_id, caption, image_url, video_url, location)
		VALUES ($1, $2, $3, $4, $5, $6)`,
		id, userID, req.Caption, req.ImageURL, req.VideoURL, req.Location)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create post"})
		return
	}

	// Update user's posts count
	h.db.Exec(`UPDATE users SET posts_count = posts_count + 1 WHERE id::text=$1`, userID)

	c.JSON(http.StatusCreated, gin.H{
		"id":      id,
		"message": "Post created!",
	})
}

// GetFeed — returns posts from people the user follows
func (h *PostHandler) GetFeed(c *gin.Context) {
	userID := c.GetString("user_id")

	// This SQL query:
	// 1. Gets posts from users that the current user follows
	// 2. Also includes the current user's own posts
	// 3. Joins with users table to get username and avatar
	// 4. Orders by newest first
	rows, err := h.db.Query(`
		SELECT p.id, p.caption, p.image_url, p.video_url, p.location,
		       p.likes_count, p.comments_count, p.created_at,
		       u.id as user_id, u.username, u.avatar_url
		FROM posts p
		JOIN users u ON u.id = p.user_id
		WHERE p.user_id::text = $1
		   OR p.user_id IN (
		      SELECT following_id FROM follows WHERE follower_id::text = $1
		   )
		ORDER BY p.created_at DESC
		LIMIT 50`, userID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get feed"})
		return
	}
	defer rows.Close()

	type Post struct {
		ID            string    `json:"id"`
		Caption       string    `json:"caption"`
		ImageURL      string    `json:"image_url"`
		VideoURL      string    `json:"video_url"`
		Location      string    `json:"location"`
		LikesCount    int       `json:"likes_count"`
		CommentsCount int       `json:"comments_count"`
		CreatedAt     time.Time `json:"created_at"`
		UserID        string    `json:"user_id"`
		Username      string    `json:"username"`
		AvatarURL     string    `json:"avatar_url"`
	}

	posts := []Post{}
	for rows.Next() {
		var p Post
		rows.Scan(&p.ID, &p.Caption, &p.ImageURL, &p.VideoURL, &p.Location,
			&p.LikesCount, &p.CommentsCount, &p.CreatedAt,
			&p.UserID, &p.Username, &p.AvatarURL)
		posts = append(posts, p)
	}

	c.JSON(http.StatusOK, gin.H{"posts": posts})
}

// GetPost — returns a single post by ID
func (h *PostHandler) GetPost(c *gin.Context) {
	postID := c.Param("id")

	var p struct {
		ID            string    `json:"id"`
		Caption       string    `json:"caption"`
		ImageURL      string    `json:"image_url"`
		VideoURL      string    `json:"video_url"`
		Location      string    `json:"location"`
		LikesCount    int       `json:"likes_count"`
		CommentsCount int       `json:"comments_count"`
		CreatedAt     time.Time `json:"created_at"`
		UserID        string    `json:"user_id"`
		Username      string    `json:"username"`
		AvatarURL     string    `json:"avatar_url"`
	}

	err := h.db.QueryRow(`
		SELECT p.id, p.caption, p.image_url, p.video_url, p.location,
		       p.likes_count, p.comments_count, p.created_at,
		       u.id, u.username, u.avatar_url
		FROM posts p
		JOIN users u ON u.id = p.user_id
		WHERE p.id::text = $1`, postID).Scan(
		&p.ID, &p.Caption, &p.ImageURL, &p.VideoURL, &p.Location,
		&p.LikesCount, &p.CommentsCount, &p.CreatedAt,
		&p.UserID, &p.Username, &p.AvatarURL)

	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"post": p})
}

// DeletePost — deletes a post (only the owner can delete)
func (h *PostHandler) DeletePost(c *gin.Context) {
	userID := c.GetString("user_id")
	postID := c.Param("id")

	// Make sure the post belongs to this user
	var ownerID string
	err := h.db.QueryRow(`SELECT user_id FROM posts WHERE id::text=$1`, postID).Scan(&ownerID)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		return
	}

	if ownerID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "You can only delete your own posts"})
		return
	}

	h.db.Exec(`DELETE FROM posts WHERE id::text=$1`, postID)
	h.db.Exec(`UPDATE users SET posts_count = posts_count - 1 WHERE id::text=$1`, userID)

	c.JSON(http.StatusOK, gin.H{"message": "Post deleted"})
}
